#!/bin/bash

# Create instance profile

# export AWS_PROFILE=buildroot-dev

set -e

# IAM role name
ROLE=$1
# Instance profile name
INSTANCE_PROFILE=${2:-$ROLE}

# echo "Creating instance profile: $INSTANCE_PROFILE"
# aws iam create-instance-profile --instance-profile-name "$INSTANCE_PROFILE"

echo "Creating role: $ROLE"
aws iam create-role \
    --role-name "$ROLE" \
    --assume-role-policy-document "file://ec2-trust-policy.json"

echo "Adding role $ROLE to instance profile $INSTANCE_PROFILE"
aws iam add-role-to-instance-profile --instance-profile-name $INSTANCE_PROFILE --role-name $ROLE
