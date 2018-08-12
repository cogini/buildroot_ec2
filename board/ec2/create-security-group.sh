#!/bin/bash

# Create a security group

# export AWS_PROFILE=cogini-dev

set -e

# Security group name
SECURITY_GROUP=$1

echo "Creating security group: $SECURITY_GROUP"
SECURITY_GROUP_ID=$( aws ec2 create-security-group \
    --group-name "$SECURITY_GROUP" \
    --description 'Nerves' \
    --query 'GroupId' --output text)

echo "Security group id: $SECURITY_GROUP_ID"

aws ec2 authorize-security-group-ingress --group-name "$SECURITY_GROUP" \
    --protocol tcp \
    --port 22 \
    --cidr "0.0.0.0/0"

aws ec2 authorize-security-group-ingress --group-name "$SECURITY_GROUP" \
    --protocol tcp \
    --port 80 \
    --cidr "0.0.0.0/0"

aws ec2 describe-security-groups --group-names "$SECURITY_GROUP"
# aws ec2 describe-security-groups --filters "Name=group-name,Values=$SECURITY_GROUP"
