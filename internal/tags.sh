#!/bin/bash

# Set error handling
set -e

# Get cluster VPC and subnets
echo "Checking cluster info..."
CLUSTER_INFO=$(aws eks describe-cluster --name dev-simetrik-eks-cluster-us1 --query "cluster.resourcesVpcConfig" --output json)
echo "Cluster info: $CLUSTER_INFO"

# Only proceed if we have valid JSON
if [ -z "$CLUSTER_INFO" ]; then
    echo "Error: No cluster information received"
    exit 1
fi

VPC_ID=$(echo "$CLUSTER_INFO" | jq -r '.vpcId')
if [ -z "$VPC_ID" ]; then
    echo "Error: Could not extract VPC ID"
    exit 1
fi

SUBNET_IDS=$(echo "$CLUSTER_INFO" | jq -r '.subnetIds | join(" ")')
if [ -z "$SUBNET_IDS" ]; then
    echo "Error: Could not extract Subnet IDs"
    exit 1
fi

echo "VPC ID: $VPC_ID"
echo "Subnet IDs: $SUBNET_IDS"

# Tag subnets
aws ec2 create-tags \
  --resources $SUBNET_IDS \
  --tags \
    Key=karpenter.sh/discovery,Value=dev-simetrik-eks-cluster-us1 \
    Key=kubernetes.io/cluster/dev-simetrik-eks-cluster-us1,Value=shared

# Tag VPC
aws ec2 create-tags \
  --resources $VPC_ID \
  --tags \
    Key=karpenter.sh/discovery,Value=dev-simetrik-eks-cluster-us1 \
    Key=kubernetes.io/cluster/dev-simetrik-eks-cluster-us1,Value=shared
