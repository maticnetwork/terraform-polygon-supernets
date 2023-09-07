This repository contains Terraform automation for deploying Polygon
Supernet infrastructure on AWS.

# Polygon Supernets AWS Deployment using Terraform / Ansible

Polygon Supernets is Polygon's solution to build and power dedicated
app-chains. Supernets are powered by Polygon's cutting-edge EVM
technology, industry-leading blockchain tools and premium end-to-end
support.

To find out more about Polygon, visit the [official
website](https://polygon.technology/polygon-supernets).

## Official Documentation 📝

If you'd like to learn more about the Polygon Supernets, how it works
and how you can use it for your project, please check out the
**[Polygon Supernets
Documentation](https://wiki.polygon.technology/docs/supernets/)**.

## Architecture Overview

The following resources will be deployed using Terraform:

- Dedicated VPC
- 4 validator nodes (which are also bootnodes)
- 1 rootchain (L1) node running Geth
- Application Load Balancer used for exposing the `JSON-RPC` endpoint

![Architecture Diagram](architecture.png)


## Requirements

In order to use these automations, you'll need a few things installed:

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) | >= 1.4.4 |
| [Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) | |
| <a name="requirement_aws"></a> [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | >= 2.11.0 |
| <a name="requirement_ansible"></a> [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) | >= 2.14 |
| <a name="requirement_boto3"></a> [boto3](https://pypi.org/project/boto3/) | >= 1.26 |
| <a name="requirement_botocore"></a> [botocore](https://pypi.org/project/botocore/) | >= 1.29 |


## Terraform Deployment Steps

1. First, you'll want to clone the project repository and change
   directories:

```
git clone git@github.com:maticnetwork/terraform-polygon-supernets.git
cd terraform-polygon-supernets
```

2. Now we'll need to make sure our command line is capable of
   executing AWS commands. To utilize AWS services, you must set up
   your AWS credentials. There are two methods to establish these
   credentials: using the AWS CLI or manually configuring them in your
   AWS console. For more information about setting up AWS credentials, check
   out the documentation provided by AWS
   [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html).

   You can use `aws configure`, `aws configure sso`, or set appropriate variables in
   `~/.aws/credentials` or in `~/.aws/config`. Alternatively, you can directly set
   access keys as shown below.

```
$ export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
$ export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
$ export AWS_DEFAULT_REGION=eu-west-1
```

Note: Ensure that the AWS user role has the necessary permissions to create all
resources listed in the `/modules` directory.

Before proceeding, verify that your AWS CLI is properly authenticated.
Execute the following command: `aws sts get-caller-identity`.
If the command runs successfully, you are ready to continue.


3. There are a few environment variables that should be set before
   provisioning the infrastructure. Customize `example.env` based on
   your requirements and then run the commands below to set your local
   environment variables.

```
set -a
source example.env
set +a
```

To verify that your environment variables have been
set correctly, run the command `env | grep -i tf_var`.
This will display the environment variables, allowing you to confirm they match the values specified in `example.env`.

The full list of variables that can be configured are in
[variables.tf](./variables.tf).

4. Now we'll run `terraform init` to download and install the provider
   plugins, which are used to interact with AWS and initialize the
   backend to store the state file.

```
terraform init
```

5. Next, we're going to "plan" and "apply" using Terraform. While working
   iteratively on your Supernet, you'll typically make changes to the
   Terraform modules, preview the potential infrastructure modifications,
   and then apply the changes if they meet your expectations.

```
terraform plan
terraform apply
```

6. While applying the Terraform configuration, a private key was generated to grant you
   access to your VMs. To save this key, use the
   following commands.

```
terraform output pk_ansible > ~/devnet_private.key
chmod 600 ~/devnet_private.key
```

By now, the necessary AWS infrastructure for operating a Supernet should be deployed.
It's a good time to sign in to your AWS Console and examine the setup.

## Ansible Deployment Steps

At this stage we'll be using Ansible to configure the VMs that we just
deployed with Terraform.

1. To begin, switch your working directory to the Ansible folder
   `ansible`.

```
cd ansible
```

2. The Ansible playbooks that we use require certain external
   dependencies. In order to retrieve these collections, you can run
   the following command:

```
ansible-galaxy install -r requirements.yml
```

3. In case you've altered your region, company name, or deployment name, remember to
   modify the `inventory/aws_ec2.yml` file accordingly.

```
regions:
  - eu-west-1
###
filters:
  tag:BaseDN: "<YOUR_DEPLOYMENT_NAME>.edge.<YOUR_COMPANY>.private"
```

The ssh configuration used by Ansible assumes that your default
profile will be configured for the same region where your VMs are
deployed. You can run `aws configure get region` and confirm that the
default matches your inventory location.

4. The `group_vars/all.yml` file contains a number of values that are
   often adjusted during Supernet deployments. At the very least,
   make sure to update the `clean_deploy_title` to match
   the deployment name you used.

   Other values like `block_gas_limit` and `block_time`
   significantly impact performance and should be set with care.

5. To verify the availability of your instances, run the following command:

```
ansible-inventory --graph
```

This command will list a bunch of instances. At this stage, it's important
to ensure that your SSM and SSH configurations allow access
to these instances based on their instance IDs. To test SSM,
execute a command similar to the one below:

```
aws ssm start-session --target [aws instance id]
```

An example instance id is `i-0641e8ff5f2a31647`. When you run this
command, you should have shell access to your VM.


6. Now that we've confirmed access to our VMs, we must verify that the instances are accessible by Ansible.
   Attempt running this command:

```
ansible all -m ping
```


7. Run ansible playbook
```
ansible-playbook site.yml
```

After the **full playbook runs, you should have a functional
Supernet**. If you want perform some tests, you can obtain your public RPC
endpoint with the following command:

```
terraform output aws_lb_ext_domain
```

By default, we are pre-funding this address:
`0x85da99c8a7c2c95964c8efd687e95e632fc533d6` which has the private key
`0x42b6e34dc21598a807dc19d7784c71b2a7a01f6480dc6f58258f78e539f1a1fa`. Using
that private key and the RPC address from the previous step you should
be able to send transactions. The command below uses
[cast](https://book.getfoundry.sh/cast/) to send a test transaction:


```
cast send --legacy \
    --rpc-url http://ext-rpc-devnet13-edge-10623089.eu-west-1.elb.amazonaws.com \
    --value 1 \
    --private-key 0x42b6e34dc21598a807dc19d7784c71b2a7a01f6480dc6f58258f78e539f1a1fa \
    0x9f34dCBECFC0BD4c1ee3d12e1Fb5DCF1A0b9BCcB
```

This command uses
[polycli](https://github.com/maticnetwork/polygon-cli) to do a simple
load test. We're not required to specify a private key here because
`0x42b6e34dc21598a807dc19d7784c71b2a7a01f6480dc6f58258f78e539f1a1fa`
is the default load test address of `polycli`:

```
polycli loadtest --chain-id 1 --mode t --requests 10 \
    --verbosity 601 http://ext-rpc-devnet13-edge-10623089.eu-west-1.elb.amazonaws.com
```

## Destroy Procedure 💥

In the root directory, run `terraform destroy`


<!-- ## Quick Deployment -->

<!-- This is a 1-click way to set up the network. The steps below and the -->
<!-- comments in run.sh describe what each command is for. If running in to -->
<!-- errors and need troubleshooting, each line from the file should be run -->
<!-- line-by-line to better identify issues. -->

<!-- Run `run.sh` -->

<br>

# Supernet Set Up
Take a look at [Supernet Set Up](./supernet-setup.md)

# Load Testing
Take a look at [Load Testing](./loadtesting.md)