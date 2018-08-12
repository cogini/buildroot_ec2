#!/bin/bash

# Create IAM role policy
# https://docs.aws.amazon.com/cli/latest/reference/iam/create-policy.html

# export AWS_PROFILE=buildroot-dev

set -e

# Role name
ROLE=$1
# Policy ARN
POLICY_ARN=$2

echo "Attaching role policy $ROLE $POLICY_ARN"
aws iam attach-role-policy \
	--role-name "$ROLE" \
	--policy-arn "$POLICY_ARN"
