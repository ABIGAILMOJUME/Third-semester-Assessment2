#!/bin/bash

echo "🧹 Manual AWS Cleanup Script"
echo "=============================="

REGION="eu-north-1"
CLUSTER_NAME="retail-store"

# Wait for node groups to be deleted
echo "⏳ Waiting for node groups to be deleted..."
while true; do
    NODEGROUPS=$(aws eks list-nodegroups --cluster-name $CLUSTER_NAME --region $REGION --query 'nodegroups' --output text 2>/dev/null)
    if [ -z "$NODEGROUPS" ] || [ "$NODEGROUPS" = "None" ]; then
        echo "✅ All node groups deleted"
        break
    fi
    echo "   Still deleting node groups: $NODEGROUPS"
    sleep 30
done

# Delete EKS cluster
echo "🗑️  Deleting EKS cluster..."
aws eks delete-cluster --name $CLUSTER_NAME --region $REGION
echo "⏳ Waiting for cluster deletion..."
aws eks wait cluster-deleted --name $CLUSTER_NAME --region $REGION

# Clean up VPCs
echo "🗑️  Cleaning up VPCs..."
VPC_IDS=$(aws ec2 describe-vpcs --region $REGION --filters "Name=tag:environment-name,Values=retail-store" --query 'Vpcs[].VpcId' --output text)

for VPC_ID in $VPC_IDS; do
    echo "🧹 Cleaning VPC: $VPC_ID"
    
    # Delete security groups
    aws ec2 describe-security-groups --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text | tr '\t' '\n' | while read sg_id; do
        if [ ! -z "$sg_id" ]; then
            echo "   Deleting security group: $sg_id"
            aws ec2 delete-security-group --group-id $sg_id --region $REGION || true
        fi
    done
    
    # Delete subnets
    aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[].SubnetId' --output text | tr '\t' '\n' | while read subnet_id; do
        if [ ! -z "$subnet_id" ]; then
            echo "   Deleting subnet: $subnet_id"
            aws ec2 delete-subnet --subnet-id $subnet_id --region $REGION || true
        fi
    done
    
    # Delete internet gateway
    aws ec2 describe-internet-gateways --region $REGION --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[].InternetGatewayId' --output text | tr '\t' '\n' | while read igw_id; do
        if [ ! -z "$igw_id" ]; then
            echo "   Detaching and deleting internet gateway: $igw_id"
            aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $VPC_ID --region $REGION || true
            aws ec2 delete-internet-gateway --internet-gateway-id $igw_id --region $REGION || true
        fi
    done
    
    # Delete VPC
    echo "   Deleting VPC: $VPC_ID"
    aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION || true
done

echo "✅ Cleanup completed!"
echo "💰 AWS charges should stop within the hour."