# Polygon Supernets AWS Terraform Deployment

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

This is an automated Polygon Supernet blockchain infrastructure
deployment for AWS cloud provider. High level overview of the
resources that will be deployed:

- Dedicated VPC
- 4 validator nodes (which are also boot nodes)
- 1 Root Chain (L1) Node running geth
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

2. Now we'll need to make sure our command like is capable of
   executing AWS commands. To utilize AWS services, you need to set up
   your AWS credentials. There are two ways to set up these
   credentials: using the AWS CLI or manually setting them up in your
   AWS console. To learn more about setting up AWS credentials, check
   out the documentation provided by AWS
   [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html). `aws
   configure`, `aws configure sso`, or set appropriate variables in
   `~/.aws/credentials` or in `~/.aws/config`. You can directly set
   access keys like below.

```
$ export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
$ export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
$ export AWS_DEFAULT_REGION=us-west-2
```

Note: The role of the AWS user should have permissions to create all
of the resources provided in `/modules`.

It's worthwhile at this point to confirm that AWS CLI is authenticated
properly. Try running this command `aws sts get-caller-identity`. If
this works, you're probably set to move forward.


3. There are a few environment variables that should be set before
   provisioning the infrastructure. Edit `example.env` based on your
   requirements and then run the commands below to set your local
   environment variables.

```
set -a
source example.env
set +a
```

You can quickly double check that your environment variables have been
set by running `env | grep -i tf_var` to double check that the
environment variables match what you specified in `example.env`

The full list of variables that can be configured are in
[variables.tf](./variables.tf).

4. Now we'll run `terraform init` to download and install the provider
   plugins, which are used to interact with AWS and initializes the
   backend to store the state file.

```
terraform init
```

5. Now we're going to plan and apply using Terraform. While working
   iteratively on your supernet, you'll typically make changes to the
   Terraform modules, then plan to see what changes will be made to
   your infrastructure, and then finally apply if the plan looks good.

```
terraform plan
terraform apply
```

6. During the Terraform apply, a private key was generated to give you
   access to your VMs. You'll need to shave that key using the
   following commands.

```
terraform output pk_ansible > ~/devnet_private.key
chmod 600 ~/devnet_private.key
```

At this point all of the AWS infrastructure needed to run a supernet
should be deployed. This is a good time to login to your AWS Console
and take a look.

## Ansible Deployment Steps

1. At this stage we'll be using Ansible to configure the VMs that we
   just deployed with Terraform. First, Change working directory to
   `ansible`.

```
cd ansible
```

2. The Ansible playbooks that we use have some external
   dependencies. In order to retrieve those collections, you can run
   the following command:

```
ansible-galaxy install -r requirements.yml
```

3. If you've changed your region, company name, or deployment name,
   you'll need to modify `inventory/aws_ec2.yml`

```
regions:
  - us-west-2
###
filters:
  tag:BaseDN: "<YOUR_DEPLOYMENT_NAME>.edge.<YOUR_COMPANY>.private"
```

4. The file `local-extra-vars.yml` has a bunch of values that are
   commonly tweaked during supernet deployments. At the very least,
   you'll probably need to change `clean_deploy_title` to match
   whatever deployment name you used.

   Some of the other values like `block_gas_limit` and `block_time`
   are important for performance and are worth setting very carefully.

5. Check if your instances are available by running the following.

```
ansible-inventory --graph
```

This command will list a bunch of instances. It's important at this
stage to make sure that your SSM and SSH are configured to be able to
reach these instances based on their instance id. To test SSM, run a
command like this:

```
aws ssm start-session --target [aws instance id]
```

An example instance id is `i-0641e8ff5f2a31647`. When you run this
command you should have shell access to your VM.


6. Now that we know we can access our VMs, we need to ensure the
   instances are reachable by Ansible. Try running this command:

```
ansible --inventory inventory/aws_ec2.yml --extra-vars "@local-extra-vars.yml" all -m ping
```


7. Run ansible playbook
```
ansible-playbook --inventory inventory/aws_ec2.yml --extra-vars "@local-extra-vars.yml" site.yml
```

After this full playbook runs you should have a functional
supernet. If you want to do some tests, you can get your public rpc
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
    --rpc-url http://ext-rpc-devnet13-edge-10623089.us-west-2.elb.amazonaws.com \
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
    --verbosity 601 http://ext-rpc-devnet13-edge-10623089.us-west-2.elb.amazonaws.com
```

## Destroy Procedure 💥

In the root directory, run `terraform destroy`


<!-- ## Quick Deployment -->

<!-- This is a 1-click way to set up the network. The steps below and the -->
<!-- comments in run.sh describe what each command is for. If running in to -->
<!-- errors and need troubleshooting, each line from the file should be run -->
<!-- line-by-line to better identify issues. -->

<!-- Run `run.sh` -->


## Terraform Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.22.0 |

## Terraform Modules

| Name | Source
|------|--------|
| <a name="module_dns"></a> [dns](#module\_dns) | ./modules/dns
| <a name="module_ebs"></a> [ebs](#module\_ebs) | ./modules/ebs
| <a name="module_ec2"></a> [ec2](#module\_ec2) | ./modules/ec2
| <a name="module_elb"></a> [elb](#module\_elb) | ./modules/elb
| <a name="module_networking"></a> [networking](#module\_networking) | ./modules/networking
| <a name="module_securitygroups"></a> [securitygroups](#module\_securitygroups) | ./modules/securitygroups
| <a name="module_ssm"></a> [ssm](#module\_ssm) | ./modules/ssm

## Ansible Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="aws_profile"></a> [aws\_profile](#aws\_profile) | The AWS profile that we're going to use | `string` | `"default"` | no |
| <a name="base_instance_type"></a> [base_instance_type](#base_instance_type) | The type of instance that we're going to use | `string` | `"c6a.large"` | no |
| <a name="company_name"></a> [company_name](#company_name) | The name of the company for this particular deployment | `string` |  | yes |
| <a name="create_ssh_key"></a> [create_ssh_key](#create_ssh_key) | Should a new ssh key be created or should we use the devnet_key_value | `string` | `""` | no |
| <a name="deployment_name"></a> [deployment_name](#deployment_name) | The unique name for this particular deployment | `string` |  | yes |
| <a name="devnet_key_value"></a> [devnet_key_value](#devnet_key_value) | The public key value to use for the ssh key. Required when create_ssh_key is false | `string` | `""` | no |
| <a name="devnet_private_subnet"></a> [devnet_private_subnet](#devnet_private_subnet) | The name of the chain data EBS volume. | `list(string)` | `["10.10.64.0/22", "10.10.68.0/22", "10.10.72.0/22", "10.10.76.0/22"]` | no |
| <a name="devnet_public_subnet"></a> [devnet_public_subnet](#devnet_public_subnet) | The cidr block for the private subnet in our VPC | `list(string)` | `["10.10.64.0/22", "10.10.68.0/22", "10.10.72.0/22", "10.10.76.0/22"]` | no |
| <a name="devnet_vpc_block"></a> [devnet_vpc_block](#devnet_vpc_block) | The cidr block for the public subnet in our VPC | `string` | `"10.10.0.0/16"` | no |
| <a name="environment"></a> [environment](#environment) | The environment for deployment for this particular deployment | `string` | `"devnet"` | no |
| <a name="fullnode_count"></a> [fullnode_count](#fullnode_count) | The number of full nodes that we're going to deploy | `number` | `0` | no |
| <a name="http_rpc_port"></a> [http_rpc_port](#http_rpc_port) | The TCP port that will be used for http rpc | `number` | `10002` | no |
| <a name="network_acl"></a> [network_acl](#network_acl) | Which CIDRs should be allowed to access the explorer and RPC. | `list(string)` | `["0.0.0.0/0"]` | no |
| <a name="node_storage"></a> [node_storage](#node_storage) | The size of the storage disk attached to full nodes and validators | `number` | `10` | no |
| <a name="owner"></a> [owner](#owner) | The main point of contact for this particular deployment. | `string` |  | yes |
| <a name="private_network_mode"></a> [private_network_mode](#private_network_mode) | True if vms should bey default run in the private subnets | `bool` | `true` | no |
| <a name="region"></a> [region](#region) | The region where we want to deploy | `string` | `"us-west-2"` | no |
| <a name="validator_count"></a> [validator_count](#validator_count) | The number of validators that we're going to deploy | `number` | `4` | no |
| <a name="zones"></a> [zones](#zones) | The availability zones for deployment | `list(string)` | `["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="aws_lb_int_rpc_domain"></a> [aws_lb_int_rpc_domain](#aws_lb_int_rpc_domain) | The dns name for the JSON-RPC API (internal) |
| <a name="aws_lb_ext_domain"></a> [aws_lb_ext_domain](#aws_lb_ext_domain) | The dns name for the JSON-RPC API (external) |
| <a name="aws_lb_ext_validator_domain"></a> [aws_lb_ext_validator_domain](#aws_lb_ext_validator_domain) | The dns name for the validator JSON-RPC API (external) |
| <a name="base_dn"></a> [base_dn](#base_dn) | The BaseDN name for the network |
| <a name="base_id"></a> [base_id](#base_id) | The Base ID for the network |
