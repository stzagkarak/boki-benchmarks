#!/bin/bash

AWS_REGION="us-east-1"
PLACEMENT_GROUP_NAME="boki-experiments"
SECURITY_GROUP_NAME="boki"

# Create placement group
aws --output text --region $AWS_REGION ec2 create-placement-group \
    --group-name $PLACEMENT_GROUP_NAME --strategy cluster

# Create security group
SECURITY_GROUP_ID=$(\
    aws --output text --region $AWS_REGION ec2 create-security-group \
    --group-name $SECURITY_GROUP_NAME --description "Boki experiments")

SECURITY_GROUP_ID='sg-0e468247e566b1a2a' # manually added. Above command not working

echo $AWS_REGION
echo $PLACEMENT_GROUP_NAME
echo $SECURITY_GROUP_NAME
echo $SECURITY_GROUP_ID

# Allow all internal traffic within the newly create security group
aws --output text --region $AWS_REGION ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --ip-permissions "IpProtocol=-1,FromPort=-1,ToPort=-1,UserIdGroupPairs=[{GroupId=$SECURITY_GROUP_ID}]"

LOCAL_IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')

echo $LOCAL_IP

# Allow SSH traffic from current machine to the newly create security group
aws --output text --region $AWS_REGION ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$LOCAL_IP/32}]"
