# Package Manager on AWS with Ubuntu Jammy 

These scripts use the AWS CLI and bash to set up various product configurations. 

## AWS CLI

1. First, set up the Amazon CLI and configure your AWS default profile: [https://positpbc.atlassian.net/wiki/spaces/ENG/pages/36343631](https://positpbc.atlassian.net/wiki/spaces/ENG/pages/36343631) and [https://docs.aws.amazon.com/cli/latest/userguide/getting-started-prereqs.html](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-prereqs.html)
    

CLI installation steps:

```
sudo apt-get update
sudo apt-get install libc6
sudo apt install glibc groff less

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip awscliv2.zip
sudo ./aws/install

/usr/local/bin/aws --version
aws --version

aws configure sso
```

This will direct you to select a profile. For example, to use the PowerUser-12345 profile specify it with:

```
aws s3 ls --profile PowerUser-12345
```

Configure this as your default by adding it to your aws config. Open the config with:

```
sudo nano ~/.aws/config
```

Add this, or the appropriate details for the account you want to set as default, to the top:

```
[default]
sso_start_url = https://rstudio.awsapps.com/start
sso_region = us-east-2
sso_account_id = 12345
sso_role_name = PowerUser
region = us-east-2
```

In the above the `12345` should be replaced with an appropriate account ID. 

Test the connection with:

```
aws-assume team-east-2 # If you have multiple profiles, declare the one you want
aws sso login
aws sts get-caller-identity
```

Or log in with a specific profile with:

```
aws sts get-caller-identity --profile PowerUser-12345
```

## Connecting to your instance remotely

In order to SSH into the instance you will have to have [set up SSM on your machine (follow the “client side” instructions](https://positpbc.atlassian.net/wiki/spaces/SE/pages/526614575).

Add this to the relevant ssh config file, usually in ~/.ssh/config

```
# SSH over Session Manager
host i-* mi-*
    ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession 
```

You can then SSH with the following command:

```
ssh -i $AWS_PRIVATE_KEY_PATH user@<instance-id> where user = ubuntu or ec2-user.
```

Alternatively, you can use the start-session command:

```
# Start session with the instance explicit
aws ssm start-session --target i-0c5e0729fe03984b5

# Change from a SSM shell to bash
sudo -s
/bin/bash
```

You can use passwordless sudo -s to become root and then su - ubuntu to become ubuntu (on ubuntu).

## Related

- [https://positpbc.atlassian.net/wiki/spaces/SE/pages/36343247](https://positpbc.atlassian.net/wiki/spaces/SE/pages/36343247)
- [https://positpbc.atlassian.net/wiki/spaces/ENG/pages/36343631](https://positpbc.atlassian.net/wiki/spaces/ENG/pages/36343631)
- [https://positpbc.atlassian.net/wiki/spaces/SE/pages/36277276](https://positpbc.atlassian.net/wiki/spaces/SE/pages/36277276)
- Katie’s repo: [https://github.com/sol-eng/proxyplayground](https://github.com/sol-eng/proxyplayground)
- SamE's pulumi recipes (private, ask for access): [https://github.com/sol-eng/pulumi-recipes](https://github.com/sol-eng/pulumi-recipes)  
- SamC's pulumi recipes (private, ask for access): [https://github.com/samcofer/pulumi_pieces](https://github.com/samcofer/pulumi_pieces)  
- Sam's cloud storage with fsbench: [https://github.com/samcofer/cloud-storage-testing](https://github.com/samcofer/cloud-storage-testing)  
- Sam's writeup on cloud storage recommendations: [https://github.com/samcofer/cloud-storage-testing/blob/main/docs/storage-recommend.qmd](https://github.com/samcofer/cloud-storage-testing/blob/main/docs/storage-recommend.qmd)


