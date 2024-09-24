#!bin/bash

# Influenced by: https://github.com/sol-eng/proxyplayground/blob/main/config/stand-up-ppm.sh

# Remember that to close vim use q

# use AWS CLI to make new ec2
aws-assume team-east-2 # us-east-2 Choose this one
aws sso login
aws sts get-caller-identity

AMI_ID=ami-0d77c9d87c7e619f9 #RHEL-9.3.0_HVM-20240117-x86_64-49-Hourly2-GP3 with EBS
INSTANCE_TYPE=t3.medium
KEY_NAME=add-your-key.pem-file
SG=sg-0d81e0f63a21da47f # lisa-sg
#SUBNET=subnet-d4ae8b98 #, subnet-08dc7bcdf8b1ae500
EC2_NAME=lisa-rhel9-workbench
OWNER=lisa.anders@posit.co
#VPC=vpc-0a451d800cba4446f #us-east-2, sol-eng team account, created a default: vpc-07d7d04d282d1e637

# Pre-req: Create a key and copy to ~
# chmod -R 600 ~/add-your-key.pem-file

# Pre-req: Create a default VPC
# Admin Console --> VPC --> Actions --> Create Default VPC

# Pre-req: Create a security group

# Stand up the instance (q to close popup)
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
EC2_DNS=ec2-3-136-155-192.us-east-2.compute.amazonaws.com

# SSH into the instance - update the name to use your key
ssh -i "~/add-your-key.pem-file" ec2-user@${EC2_DNS}

# Add someone else's ssh public keys to ec2: (after pasting in, press Ctl+D to exit the cat)
#cat >> .ssh/authorized_keys
#ssh-rsa <key> <instance>

# visit it at: http://ec2-3-136-155-192.us-east-2.compute.amazonaws.com:8787

# when you're done, the EC2 can be terminated
#aws ec2 terminate-instances --instance-ids $INSTANCE_ID
