#!bin/bash

# Influenced by: https://github.com/sol-eng/proxyplayground/blob/main/config/stand-up-ppm.sh

# use AWS CLI to make new ec2
aws sso login
aws sts get-caller-identity

AMI_ID=ami-00eeedc4036573771 #Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
INSTANCE_TYPE=t3.medium
KEY_NAME=add-your-key-name-without.pem-file
SG=sg-0d81e0f63a21da47f
EC2_NAME=lisa-connect
OWNER=lisa.anders@posit.co
#VPC=vpc-07d7d04d282d1e637

# Pre-req: Create a key and copy to ~
#chmod -R 600 ~/add-your-key-name.pem

# Pre-req: Create a default VPC
# Admin Console --> VPC --> Actions --> Create Default VPC

# Pre-req: If not already created, create a security group as shown in the PPM example

# Stand up the instance 
aws ec2 run-instances \
    --image-id ${AMI_ID} \
    --count 1 \
    --instance-type ${INSTANCE_TYPE} \
    --key-name ${KEY_NAME} \
    --security-group-ids ${SG} \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${EC2_NAME}},{Key=rs:project,Value=solutions},{Key=rs:owner,Value=lisa.anders@posit.co}]" \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sdf\",\"Ebs\":{\"VolumeSize\":32,\"DeleteOnTermination\":true}}]"

# tell me the DNS name
aws ec2 describe-instances --filters "Name=tag:Name,Values=${EC2_NAME}" --output table | grep PublicDnsName 

# paste the DNS name in here so it's easier to ssh into
EC2_DNS=ec2-18-189-29-186.us-east-2.compute.amazonaws.com

# SSH into the instance - update the name to use your key
ssh -i "~/add-your-key-name-without.pem" ubuntu@${EC2_DNS}
ssh -i "~/${KEY_NAME}" ubuntu@${EC2_DNS}

# After installation
# visit it through a browser at: http://ec2-18-189-29-186.us-east-2.compute.amazonaws.com:3939
