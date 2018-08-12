#!/bin/bash

# Create a snapshot from a volume, create an AMI, then launch an instance from it

# export AWS_PROFILE=cogini-dev

set -e

VOLUME_ID=$1
SECURITY_GROUP=buildroot
NAME=buildroot
TAG_OWNER=jake
KEYPAIR=buildroot
IAM_INSTANCE_PROFILE=buildroot

SECURITY_GROUP_ID=$( aws ec2 describe-security-groups \
    --group-names "$SECURITY_GROUP" \
    --query "SecurityGroups[0].GroupId" --output text)

getVolumeIdentifier() {
  aws ec2 describe-instances \
    --instance-id $1 \
    --query 'Reservations[0].Instances[0].BlockDeviceMappings[?DeviceName==`/dev/sdb`].Ebs[].VolumeId' \
    --output text
}

waitForInstanceState() {
  while [ ! $( aws ec2 describe-instances \
                 --instance-id $1 \
                 --query Reservations[0].Instances[0].State.Name \
                 --output text) = $2 ]
    do sleep 5
  done
}

waitForSnapshotState() {
  while [ ! $( aws ec2 describe-snapshots \
                 --snapshot-id $1 \
                 --query Snapshots[0].State \
                 --output text) = $2 ]
    do sleep 5
  done
}

getInstanceIp() {
  aws ec2 describe-instances \
    --instance-id $1 \
    --query 'Reservations[0].Instances[0].NetworkInterfaces[0].Association.PublicIp' \
    --output text
}

waitForConsoleOutput() {
  CONSOLE_OUTPUT=$( aws ec2 get-console-output \
      --instance-id "$INSTANCE_ID" \
     --query 'Output' --output text)
  while [ "$CONSOLE_OUTPUT" = "None" ]
    do sleep 5
  done
  echo "$CONSOLE_OUTPUT"
}

# https://docs.aws.amazon.com/cli/latest/reference/ec2/create-snapshot.html

echo "Creating snapshot of volume $VOLUME_ID"
SNAPSHOT_ID=$( aws ec2 create-snapshot \
    --volume-id "$VOLUME_ID" \
    --description 'Volume for AMI' \
    --query 'SnapshotId' --output text)

waitForSnapshotState "$SNAPSHOT_ID" 'completed'

echo "Registering image with snapshot $SNAPSHOT_ID"
IMAGE_ID=$(aws ec2 register-image --architecture x86_64 \
    --block-device-mappings "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=true,SnapshotId=$SNAPSHOT_ID,VolumeSize=1,VolumeType=gp2}" \
    --name "$NAME $SNAPSHOT_ID" --root-device-name /dev/sda1 --virtualization-type hvm \
    --ena-support --sriov-net-support simple \
    --query 'ImageId' --output text)

echo "Starting instance with AMI $IMAGE_ID"
# INSTANCE_ID=$(aws ec2 run-instances --image-id "$IMAGE_ID" --instance-type t2.micro --key-name $KEYPAIR \
#     --associate-public-ip-address --security-group-ids $SECURITY_GROUP_ID \
#     --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NAME},{Key=owner,Value=$TAG_OWNER}]" \
#     --query Instances[0].InstanceId --output text)

INSTANCE_ID=$(aws ec2 run-instances --image-id "$IMAGE_ID" --instance-type t2.micro --key-name $KEYPAIR \
    --associate-public-ip-address --security-group-ids $SECURITY_GROUP_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NAME},{Key=owner,Value=$TAG_OWNER}]" \
    --user-data "Hello Buildroot" \
    --iam-instance-profile "Name=$IAM_INSTANCE_PROFILE" \
    --query Instances[0].InstanceId --output text)

waitForInstanceState "$INSTANCE_ID" "running"

INSTANCE_IP=$(aws ec2 describe-instances --instance-id "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].NetworkInterfaces[0].Association.PublicIp' --output text)

echo "Instance public IP: $INSTANCE_IP"
# echo "AMI: $IMAGE_ID"
# echo "InstanceId: $INSTANCE_ID"
# echo "Instance IP: $INSTANCE_IP"

echo "aws ec2 get-console-output --instance-id "$INSTANCE_ID" --query 'Output' --output text"

# waitForConsoleOutput
