#!/bin/bash
set +e  # Don't exit on errors - we want to try everything

# ========= CONFIG ==========
REGION="us-east-1"
VPC_ID="vpc-059c1d729c333e06d"
# ===========================

echo "🧹 Cleaning up resources for VPC: $VPC_ID in region: $REGION"
echo "================================================================"

# Function to wait with spinner
wait_with_message() {
    local seconds=$1
    local message=$2
    echo -n "$message"
    for ((i=1; i<=seconds; i++)); do
        sleep 1
        echo -n "."
    done
    echo " done"
}

# 1. Delete Load Balancers FIRST (they take longest)
echo ""
echo "📍 Step 1: Deleting Load Balancers..."
LB_ARNS=$(aws elbv2 describe-load-balancers \
  --region "$REGION" \
  --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" \
  --output text 2>/dev/null)

for LB_ARN in $LB_ARNS; do
  echo "  Deleting Load Balancer: $LB_ARN"
  aws elbv2 delete-load-balancer --load-balancer-arn "$LB_ARN" --region "$REGION" 2>/dev/null
done

if [ -n "$LB_ARNS" ]; then
  wait_with_message 60 "  Waiting for Load Balancers to delete (60s)"
fi

# 2. Delete NAT Gateways
echo ""
echo "📍 Step 2: Deleting NAT Gateways..."
NAT_IDS=$(aws ec2 describe-nat-gateways \
  --region "$REGION" \
  --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available,pending,deleting" \
  --query "NatGateways[*].NatGatewayId" \
  --output text 2>/dev/null)

for NAT_ID in $NAT_IDS; do
  echo "  Deleting NAT Gateway: $NAT_ID"
  aws ec2 delete-nat-gateway --nat-gateway-id "$NAT_ID" --region "$REGION" 2>/dev/null
done

if [ -n "$NAT_IDS" ]; then
  wait_with_message 90 "  Waiting for NAT Gateways to delete (90s)"
  # Additional wait check
  echo "  Verifying NAT Gateway deletion..."
  aws ec2 wait nat-gateway-deleted --nat-gateway-ids $NAT_IDS --region "$REGION" 2>/dev/null || echo "  (timed out, continuing anyway)"
fi

# 3. Delete VPC Endpoints
echo ""
echo "�� Step 3: Deleting VPC Endpoints..."
VPC_ENDPOINT_IDS=$(aws ec2 describe-vpc-endpoints \
  --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "VpcEndpoints[*].VpcEndpointId" \
  --output text 2>/dev/null)

for VPC_ENDPOINT_ID in $VPC_ENDPOINT_IDS; do
  echo "  Deleting VPC Endpoint: $VPC_ENDPOINT_ID"
  aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "$VPC_ENDPOINT_ID" --region "$REGION" 2>/dev/null
done

if [ -n "$VPC_ENDPOINT_IDS" ]; then
  wait_with_message 30 "  Waiting for VPC Endpoints to delete (30s)"
fi

# 4. Delete Network Interfaces
echo ""
echo "📍 Step 4: Deleting Network Interfaces..."
ENI_IDS=$(aws ec2 describe-network-interfaces \
  --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "NetworkInterfaces[*].NetworkInterfaceId" \
  --output text 2>/dev/null)

for ENI_ID in $ENI_IDS; do
  echo "  Attempting to delete ENI: $ENI_ID"
  # Try to detach first if attached
  aws ec2 detach-network-interface --attachment-id $(aws ec2 describe-network-interfaces --network-interface-ids "$ENI_ID" --region "$REGION" --query 'NetworkInterfaces[0].Attachment.AttachmentId' --output text 2>/dev/null) --region "$REGION" --force 2>/dev/null
  sleep 2
  aws ec2 delete-network-interface --network-interface-id "$ENI_ID" --region "$REGION" 2>/dev/null
done

if [ -n "$ENI_IDS" ]; then
  wait_with_message 20 "  Waiting for ENIs to delete (20s)"
fi

# 5. Detach and Delete Internet Gateways
echo ""
echo "📍 Step 5: Detaching and Deleting Internet Gateways..."
IGW_IDS=$(aws ec2 describe-internet-gateways \
  --region "$REGION" \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query "InternetGateways[*].InternetGatewayId" \
  --output text 2>/dev/null)

for IGW_ID in $IGW_IDS; do
  echo "  Detaching IGW: $IGW_ID"
  aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --region "$REGION" 2>/dev/null
  sleep 5
  echo "  Deleting IGW: $IGW_ID"
  aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID" --region "$REGION" 2>/dev/null
done

# 6. Release Elastic IPs
echo ""
echo "📍 Step 6: Releasing Elastic IPs..."
EIP_ALLOCS=$(aws ec2 describe-addresses \
  --region "$REGION" \
  --filters "Name=domain,Values=vpc" \
  --query "Addresses[?AssociationId!=null || NetworkInterfaceId!=null].AllocationId" \
  --output text 2>/dev/null)

for EIP_ID in $EIP_ALLOCS; do
  echo "  Releasing EIP: $EIP_ID"
  aws ec2 release-address --allocation-id "$EIP_ID" --region "$REGION" 2>/dev/null
done

# 7. Delete Target Groups
echo ""
echo "📍 Step 7: Deleting Target Groups..."
TG_ARNS=$(aws elbv2 describe-target-groups \
  --region "$REGION" \
  --query "TargetGroups[?VpcId=='$VPC_ID'].TargetGroupArn" \
  --output text 2>/dev/null)

for TG_ARN in $TG_ARNS; do
  echo "  Deleting Target Group: $TG_ARN"
  aws elbv2 delete-target-group --target-group-arn "$TG_ARN" --region "$REGION" 2>/dev/null
done

# 8. Delete Route Tables (except main)
echo ""
echo "📍 Step 8: Deleting Route Tables..."
RTB_IDS=$(aws ec2 describe-route-tables \
  --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "RouteTables[?Associations[0].Main!=\`true\`].RouteTableId" \
  --output text 2>/dev/null)

for RTB_ID in $RTB_IDS; do
  # First, disassociate any explicit associations
  ASSOC_IDS=$(aws ec2 describe-route-tables \
    --route-table-ids "$RTB_ID" \
    --region "$REGION" \
    --query "RouteTables[0].Associations[?!Main].RouteTableAssociationId" \
    --output text 2>/dev/null)
  
  for ASSOC_ID in $ASSOC_IDS; do
    echo "  Disassociating route table association: $ASSOC_ID"
    aws ec2 disassociate-route-table --association-id "$ASSOC_ID" --region "$REGION" 2>/dev/null
  done
  
  echo "  Deleting Route Table: $RTB_ID"
  aws ec2 delete-route-table --route-table-id "$RTB_ID" --region "$REGION" 2>/dev/null
done

# 9. Delete Subnets
echo ""
echo "📍 Step 9: Deleting Subnets..."
SUBNET_IDS=$(aws ec2 describe-subnets \
  --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "Subnets[*].SubnetId" \
  --output text 2>/dev/null)

for SUBNET_ID in $SUBNET_IDS; do
  echo "  Deleting Subnet: $SUBNET_ID"
  aws ec2 delete-subnet --subnet-id "$SUBNET_ID" --region "$REGION" 2>/dev/null
done

# 10. Delete Security Groups (except default)
echo ""
echo "📍 Step 10: Deleting Security Groups..."
SG_IDS=$(aws ec2 describe-security-groups \
  --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[?GroupName!='default'].GroupId" \
  --output text 2>/dev/null)

# First pass: remove all rules
for SG_ID in $SG_IDS; do
  echo "  Removing rules from SG: $SG_ID"
  # Remove ingress rules
  aws ec2 describe-security-groups --group-ids "$SG_ID" --region "$REGION" --query "SecurityGroups[0].IpPermissions" --output json 2>/dev/null | \
    xargs -I {} aws ec2 revoke-security-group-ingress --group-id "$SG_ID" --ip-permissions {} --region "$REGION" 2>/dev/null
  # Remove egress rules
  aws ec2 describe-security-groups --group-ids "$SG_ID" --region "$REGION" --query "SecurityGroups[0].IpPermissionsEgress" --output json 2>/dev/null | \
    xargs -I {} aws ec2 revoke-security-group-egress --group-id "$SG_ID" --ip-permissions {} --region "$REGION" 2>/dev/null
done

# Second pass: delete security groups
for SG_ID in $SG_IDS; do
  echo "  Deleting Security Group: $SG_ID"
  aws ec2 delete-security-group --group-id "$SG_ID" --region "$REGION" 2>/dev/null
done

# 11. Finally delete the VPC
echo ""
echo "📍 Step 11: Deleting VPC..."
aws ec2 delete-vpc --vpc-id "$VPC_ID" --region "$REGION" 2>/dev/null && echo "✅ VPC deleted successfully!" || echo "❌ VPC
