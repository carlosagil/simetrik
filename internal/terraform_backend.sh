#!/bin/bash

# Set error handling
set -e

# Variables
BUCKET_NAME="gilcamargo-terraform"
TABLE_NAME="gilcamargo-terraform-lock"

echo "Starting terraform infra setup..."

# Create S3 bucket
echo "Creating S3 bucket: $BUCKET_NAME"
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Bucket already exists"
else
    aws s3api create-bucket --bucket "$BUCKET_NAME"
    echo "Bucket created successfully"
fi

# Enable versioning on the bucket
echo "Enabling versioning on bucket: $BUCKET_NAME"
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# Check if DynamoDB table exists
if aws dynamodb describe-table --table-name "$TABLE_NAME" 2>/dev/null; then
    echo "DynamoDB table already exists"
else
    echo "Creating DynamoDB table: $TABLE_NAME"
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST

    
    # Wait for table to be created
    echo "Waiting for table to be active..."
    aws dynamodb wait table-exists --table-name "$TABLE_NAME"
fi

echo "Setup completed successfully!"
