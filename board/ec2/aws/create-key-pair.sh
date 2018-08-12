#!/bin/bash

# Create a key pair

# export AWS_PROFILE=cogini-dev

set -e

# Key pair name
KEYPAIR=$1

echo "Creating key pair: $KEYPAIR"
aws ec2 create-key-pair --key-name "$KEYPAIR" \
    --query 'KeyMaterial' --output text
