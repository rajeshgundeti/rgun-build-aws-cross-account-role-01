# Cross-Account Role Setup for GitLab Runner in AWS



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



This guide explains how to configure cross-account roles for a GitLab runner in your DevOps AWS account to deploy resources in two different AWS accounts: **Account A (Development)** and **Account B (Production)**.

## Steps Overview

1. **Create IAM Roles** in Account A (Development) and Account B (Production).
2. **Configure Trust Relationship** for each role to allow the GitLab runner to assume the roles.
3. **Create an IAM Policy** in the DevOps account to allow the GitLab runner to assume the roles in Account A and Account B.
4. **Update the GitLab CI/CD pipeline** to assume the correct roles during deployment.
5. **Test the deployment** in both Account A and Account B.

## Step 1: Create IAM Roles in Account A (Development) and Account B (Production)

### 1.1: Create IAM Role in Account A (Development)

1. Log in to **Account A (Development)** via the AWS Management Console.
2. Navigate to **IAM > Roles** and create a new role.
3. Select **Another AWS account** as the trusted entity and provide the **Account ID** of the **DevOps account** where the GitLab runner is configured.
4. Optionally, check **Require external ID** for additional security.
5. Attach the required permissions that allow the role to perform actions in **Account A**, such as CloudFormation, EC2, and S3 permissions.
6. Name the role something like `GitLabRunnerDeployRole-Dev`.

### 1.2: Create IAM Role in Account B (Production)

Repeat the same steps as in Account A, but create the role in **Account B (Production)** with similar permissions, naming the role `GitLabRunnerDeployRole-Prod`.

## Step 2: Configure Trust Relationship for Each Role

### 2.1: Configure Trust Relationship in Account A

1. In **Account A**, navigate to **IAM > Roles**.
2. Select the role created in step 1 (`GitLabRunnerDeployRole-Dev`).
3. Go to the **Trust Relationships** tab and update the trust relationship to allow the DevOps account to assume the role.

### 2.2: Configure Trust Relationship in Account B

Repeat the same process in **Account B**, updating the trust relationship for the role `GitLabRunnerDeployRole-Prod` to allow the DevOps account to assume it.

## Step 3: Create IAM Policy for GitLab Runner in the DevOps Account

1. Log in to the **DevOps account**.
2. Navigate to **IAM > Policies** and create a new policy that grants permission to assume the roles in **Account A** and **Account B**.
3. Attach this policy to the **IAM role** or **user** used by the GitLab runner.

## Step 4: Update GitLab CI/CD Pipeline with Role ARNs

1. In your GitLab pipeline, configure it to assume the correct roles using environment variables for **Development** and **Production** environments.
2. Use the AWS CLI to automate the role assumption process based on the target environment.

## Step 5: Test the Deployment

1. Run a deployment targeting **Account A (Development)** and ensure that the GitLab runner can assume the `GitLabRunnerDeployRole-Dev` role and deploy resources successfully.
2. Repeat the test for **Account B (Production)**, verifying that the GitLab runner assumes the `GitLabRunnerDeployRole-Prod` role.

If both tests pass, the cross-account role configuration is complete, and the GitLab runner can now deploy resources in both **Development** and **Production** accounts.

---

This setup allows for a secure and efficient way for your GitLab runner to deploy resources across multiple AWS accounts.

