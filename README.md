# rgun-build-aws-cft-01



## Repository Structure 
The repository structure will now include a parameters folder where JSON files for CloudFormation parameters will be stored:

```
.
├── .gitlab-ci.yml
├── cloudformation/
│   ├── network-stack.yml
│   ├── app-stack.yml
├── parameters/
│   ├── dev-<stake_name>-parameters.json
│   ├── prod-<stack_name>-parameters.json
└── scripts/
    ├── deploy-cloudformation.sh

```

## Sample Parameter JSON File 
The JSON file defines parameters that will be injected into the CloudFormation stack during deployment. For example, here’s a dev-parameters.json file that provides values for the stack’s parameters:

```
{
    "Parameters": {
        "VpcCidr": "10.0.0.0/16",
        "SubnetCidr": "10.0.1.0/24",
        "InstanceType": "t2.micro",
        "KeyName": "my-keypair"
    }
}
```

In this example:

VpcCidr, SubnetCidr, InstanceType, and KeyName are the parameters that will be passed to the CloudFormation stack.


##  Updated CloudFormation Templates 
Network Stack (network-stack.yml)
Updated to accept parameters:

```
AWSTemplateFormatVersion: '2010-09-09'
Parameters:
  VpcCidr:
    Description: "The CIDR block for the VPC"
    Type: String
    Default: "10.0.0.0/16"
  SubnetCidr:
    Description: "The CIDR block for the subnet"
    Type: String
    Default: "10.0.1.0/24"

Resources:
  MyVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCidr
      EnableDnsSupport: true
      EnableDnsHostnames: true
      Tags:
        - Key: Name
          Value: MyVPC

  MySubnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref MyVPC
      CidrBlock: !Ref SubnetCidr
      AvailabilityZone: !Select [ 0, !GetAZs ]
      Tags:
        - Key: Name
          Value: MySubnet
```

## Application Stack (app-stack.yml)
Updated to accept parameters:

```
AWSTemplateFormatVersion: '2010-09-09'
Parameters:
  InstanceType:
    Description: "EC2 instance type"
    Type: String
    Default: "t2.micro"
  KeyName:
    Description: "KeyPair name for SSH access"
    Type: AWS::EC2::KeyPair::KeyName
    Default: "my-keypair"

Resources:
  MyInstance:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: !Ref InstanceType
      KeyName: !Ref KeyName
      SubnetId: !Ref MySubnet
      ImageId: ami-0c55b159cbfafe1f0  # Update with a valid AMI ID

```

## GitLab CI/CD Configuration (.gitlab-ci.yml)
The .gitlab-ci.yml is updated to pass the parameters JSON file during the deployment stage.


```
stages:
  - validate
  - deploy

variables:
  AWS_REGION: "us-west-2"
  STACK_NAME: "my-cloudformation-stack"
  PARAMETERS_FILE: "parameters/dev-parameters.json" # Modify this for different environments

validate_cloudformation:
  stage: validate
  image: amazon/aws-cli:latest
  script:
    - aws cloudformation validate-template --template-body file://cloudformation/network-stack.yml
    - aws cloudformation validate-template --template-body file://cloudformation/app-stack.yml
  only:
    - main

deploy_cloudformation:
  stage: deploy
  image: amazon/aws-cli:latest
  script:
    - chmod +x ./scripts/deploy-cloudformation.sh
    - ./scripts/deploy-cloudformation.sh "network-stack.yml" $STACK_NAME $PARAMETERS_FILE
  environment:
    name: production
  only:
    - main
```

## Updated Deployment Script (deploy-cloudformation.sh)
The script is updated to include the --parameters argument, which passes the parameter JSON file to the CloudFormation stack.

```
#!/bin/bash

set -e

TEMPLATE_FILE=$1
STACK_NAME=$2
PARAMETERS_FILE=$3

if [ -z "$TEMPLATE_FILE" ] || [ -z "$STACK_NAME" ] || [ -z "$PARAMETERS_FILE" ]; then
  echo "Usage: $0 <template-file> <stack-name> <parameters-file>"
  exit 1
fi

# Check if the stack already exists
stack_exists=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $AWS_REGION --query "Stacks[0].StackStatus" --output text || echo "DOES_NOT_EXIST")

if [ "$stack_exists" == "DOES_NOT_EXIST" ]; then
  echo "Stack does not exist. Creating..."
  aws cloudformation create-stack \
    --stack-name $STACK_NAME \
    --template-body file://cloudformation/$TEMPLATE_FILE \
    --parameters file://$PARAMETERS_FILE \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $AWS_REGION

  aws cloudformation wait stack-create-complete --stack-name $STACK_NAME --region $AWS_REGION
else
  echo "Stack exists. Updating..."
  aws cloudformation update-stack \
    --stack-name $STACK_NAME \
    --template-body file://cloudformation/$TEMPLATE_FILE \
    --parameters file://$PARAMETERS_FILE \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $AWS_REGION

  aws cloudformation wait stack-update-complete --stack-name $STACK_NAME --region $AWS_REGION
fi

echo "CloudFormation stack $STACK_NAME processed successfully."
```

