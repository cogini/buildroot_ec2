#!/bin/bash

# Create IAM role policy
# https://docs.aws.amazon.com/cli/latest/reference/iam/create-policy.html

# export AWS_PROFILE=buildroot-dev

set -e

# Policy name
POLICY=$1
# Path to policy JSON file
POLICY_DOCUMENT=$2

echo "Creating policy: $POLICY"
aws iam create-policy \
    --policy-name "$POLICY" \
    --policy-document "file://$POLICY_DOCUMENT" \
    --description 'Buildroot'
