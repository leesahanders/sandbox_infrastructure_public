#!bin/bash

# Influenced by: https://github.com/sol-eng/proxyplayground/blob/main/config/stand-up-ppm.sh

# use AWS CLI to make new ec2
aws sso login
aws sts get-caller-identity # verify

AMI_ID=ami-00eeedc4036573771 #Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
INSTANCE_TYPE=t3.medium
KEY_NAME=add-your-key-name-without.pem-file
SG=sg-0d81e0f63a21da47f 
EC2_NAME=lisa-ppm
OWNER=lisa.anders@posit.co
#VPC=vpc-07d7d04d282d1e637 # whatever your default is

# Pre-req: Create a key and copy to ~
# chmod -R 600 ~/add-your-key-name.pem # recommended permissions

# Pre-req: Create a default VPC
# Admin Console --> VPC --> Actions --> Create Default VPC

# Create a security group
aws ec2 create-security-group --group-name lisa-sg \
    --description "lisas security group" 
    # --vpc-id ${VPC}

# Revoke a rule - example
#aws ec2 revoke-security-group-ingress \
#    --group-name lisa-sg --ip-permissions \
#    IpProtocol=tcp,FromPort=8787,ToPort=8787,IpRanges="[{CidrIp=0.0.0.0/0}]" 

# Add a single rule - example
#aws ec2 authorize-security-group-ingress \
#    --group-name lisa-sg --ip-permissions \
#    IpProtocol=tcp,FromPort=8787,ToPort=8787,IpRanges="[{CidrIp=0.0.0.0/0,Description='Posit Workbench Web UI'}]"
    # --vpc-id vpc-1a2b3c4d

# Add multiple rules 
aws ec2 authorize-security-group-ingress \
    --group-name lisa-sg --ip-permissions \
    IpProtocol=tcp,FromPort=8787,ToPort=8787,IpRanges="[{CidrIp=0.0.0.0/0,Description='Posit Workbench Web UI'}]" \
    IpProtocol=tcp,FromPort=5559,ToPort=5559,IpRanges="[{CidrIp=0.0.0.0/0,Description='Posit Workbench Launcher'}]" \
    IpProtocol=tcp,FromPort=8888,ToPort=8898,IpRanges="[{CidrIp=0.0.0.0/0,Description='Jupyter'}]" \
    IpProtocol=tcp,FromPort=3939,ToPort=3939,IpRanges="[{CidrIp=0.0.0.0/0,Description='Connect'}]" \
    IpProtocol=tcp,FromPort=4242,ToPort=4242,IpRanges="[{CidrIp=0.0.0.0/0,Description='RSPM'}]" \
    IpProtocol=tcp,FromPort=13939,ToPort=13939,IpRanges="[{CidrIp=0.0.0.0/0,Description='Connect setup assistant'}]" \
    IpProtocol=tcp,FromPort=32768,ToPort=60999,IpRanges="[{CidrIp=0.0.0.0/0,Description='Allow connection on ephemeral ports as defined by /proc/sys/net/ipv4/ip_local_port_range - needed for both SLURM and RStudio IDE sessions'}]" \
    IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges="[{CidrIp=0.0.0.0/0,Description='SSH'}]" \
    IpProtocol=tcp,FromPort=111,ToPort=111,IpRanges="[{CidrIp=0.0.0.0/0,Description='Portmapper'}]" \
    IpProtocol=tcp,FromPort=2049,ToPort=2049,IpRanges="[{CidrIp=0.0.0.0/0,Description='NFS/EFS'}]" \
    IpProtocol=tcp,FromPort=5432,ToPort=5432,IpRanges="[{CidrIp=0.0.0.0/0,Description='PostgreSQL DB'}]" \
    IpProtocol=tcp,FromPort=3306,ToPort=3306,IpRanges="[{CidrIp=0.0.0.0/0,Description='MYSQL/Aurora'}]" \
    IpProtocol=tcp,FromPort=6817,ToPort=6817,IpRanges="[{CidrIp=0.0.0.0/0,Description='SLURM Controller Daemon (slurmctld)'}]" \
    IpProtocol=tcp,FromPort=6818,ToPort=6818,IpRanges="[{CidrIp=0.0.0.0/0,Description='SLURM Compute Node Daemon (slurmd)'}]" \
    IpProtocol=tcp,FromPort=389,ToPort=389,IpRanges="[{CidrIp=0.0.0.0/0,Description='LDAP'}]" \
    IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges="[{CidrIp=0.0.0.0/0,Description='HTTP'}]" \
    IpProtocol=tcp,FromPort=443,ToPort=443,IpRanges="[{CidrIp=0.0.0.0/0,Description='HTTPS'}]" 

## Preview the security group - close with q
aws ec2 describe-security-groups \
    --group-name lisa-sg

# Stand up the instance - close with q
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
EC2_DNS=ec2-3-22-168-28.us-east-2.compute.amazonaws.com

# SSH into the instance - update the name to use your key
ssh -i "~/add-your-key-name.pem" ubuntu@${EC2_DNS}

# After installation
# visit it at: http://ec2-3-22-168-28.us-east-2.compute.amazonaws.com:4242