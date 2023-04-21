<!-- BEGIN_TF_DOCS -->

# Polygon Supernets AWS Terraform

Polygon Supernets is Polygon's solution to build and power dedicated app-chains. Supernets are powered by Polygon's cutting-edge EVM technology, industry-leading blockchain tools and premium end-to-end support. 

To find out more about Polygon, visit the [official website](https://polygon.technology/polygon-supernets).

## Official Documentation 📝

If you'd like to learn more about the Polygon Supernets, how it works and how you can use it for your project,
please check out the **[Polygon Supernets Documentation](https://wiki.polygon.technology/docs/supernets/)**.

## Deploying resources with Terraform `/modules`

This is a fully automated Polygon Supernet blockchain infrastructure deployment for AWS cloud provider.

 - High level overview of the resources that will be deployed:
* Dedicated VPC
* 4 validator nodes (which are also boot nodes)
* 3 NAT gateways to allow nodes outbound internet traffic
* Dedicated security groups and IAM roles
* Application Load Balancer used for exposing the `JSON-RPC` endpoint

### Base AMI upgrade
This deployment uses `ubuntu-jammy-22.04-amd64-server` AWS AMI. It will **not** trigger EC2 *redeployment* if the AWS AMI gets updated.

If, for some reason, base AMI is required to get updated,
it can be achieved by running `terraform taint` command for each instance, before `terraform apply`.   
Instances can be tainted by running the `terraform taint module.instances[<instance_number>].aws_instance.polygon_edge_instance` command.

Example:
```shell
terraform taint module.instances[0].aws_instance.polygon_edge_instance
terraform taint module.instances[1].aws_instance.polygon_edge_instance
terraform taint module.instances[2].aws_instance.polygon_edge_instance
terraform taint module.instances[3].aws_instance.polygon_edge_instance
terraform apply
```
## Configuring Nodes with Ansible `/ansible`
*  generating the first (`genesis`) block and starting the chain

### Prerequisites
Variables that must be provided, before running the deployment:
* `premine` - the account/s that will receive pre mined native currency.
  Value must follow the official [CLI](https://wiki.polygon.technology/docs/supernets/operate/supernets-local-deploy#3-create-a-genesis-file) flag specification.

### Fault tolerance
By placing each node in a single AZ, the whole blockchain cluster is fault-tolerant to a single node (AZ) failure, as Polygon Supernets implements PolyBFT consensus which allows a single node to fail in a 4 validator node cluster.

### Command line access

Validator nodes are not exposed in any way to the public internet (JSON-PRC is accessed only via ALB) and they don't have public IP addresses attached to them. Nodes command line access is possible only via ***AWS Systems Manager - Session Manager***.



## Resources cleanup
Run `terraform destroy` when cleaning up all resources.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) | >= 1.4.4 |
| <a name="requirement_aws"></a> [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | >= 2.11.0 |
| <a name="requirement_ansible"></a> [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) | >= 2.14 |
| <a name="requirement_boto3"></a> [boto3](https://pypi.org/project/boto3/) | >= 1.26 |
| <a name="requirement_botocore"></a> [botocore](https://pypi.org/project/botocore/) | >= 1.29 |


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
<!-- END_TF_DOCS -->

## Quick Deployment
Run `run.sh`

## Terraform Deployment Steps
1. Clone the repo
```
git clone git@github.com:maticnetwork/terraform-polygon-supernets.git
```
2. Change the current working directory to `terraform-polygon-supernets`.
```
cd terraform-polygon-supernets
```
3. Configure AWS on your terminal. To utilize AWS services, you need to set up your AWS credentials. There are two ways to set up these credentials: using the AWS CLI or manually setting them up in your AWS console. To learn more about setting up AWS credentials, check out the documentation provided by AWS [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html). `aws configure`, `aws configure sso`, or set appropriate variables in `~/.aws/credentials` or in `~/.aws/config`. You can directly set access keys like below. 
```
$ export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
$ export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
$ export AWS_DEFAULT_REGION=us-west-2
```
Note: The role of the AWS user should have permissions to create all of the resources provided in `/modules`.
4. Set the environment variables. See `example.env`.
```
set -a       
source example.env
set +a
```
5. Run `terraform init`. Terraform downloads and installs the provider plugins, which are used to interact with AWS and initializes the backend to store the state file.
```
terraform init
```
5. Run `terraform plan`. Terraform compares the desired state (as defined in your Terraform configuration files) to the current state of your infrastructure and determines what actions need to be taken to achieve the desired state.
```
terraform plan
```
6. Run `terraform apply`. Terraform creates, modifies, or deletes resources as necessary to achieve the desired state.

```
terraform apply -auto-approve
```
7. Save `terraform output pk_ansible` to a file. And change permissions so that only the owner of the file can read and write to the file.
```
terraform output pk_ansible > ~/devnet_private.key
chmod 600 ~/devnet_private.key 
eval "$(ssh-agent)"
ssh-add ~/devnet_private.key 
```

## Ansible Deployment Steps
1. Change working directory to ansible
```
cd ansible
```
2. Create the ansible vault passwords file. Then store your vault password securely in a file or a secret manager.
```
touch password.txt
VAULT_PASSWORD=*********************
echo $VAULT_PASSWORD> > password.txt
```
3. Modify the `amazon.aws.aws_ec2` plugin is correctly filtering with the right basedn in `inventory/aws_ec2.yml`.
```
filters:
  tag:BaseDN: "<YOUR_DEPLOYMENT_NAME>.edge.<YOUR_COMPANY>.private"
```
4. Set the following variables in `local-extra-vars.yml`.
```
clean_deploy_title: devnet01 # YOUR_DEPLOYMENT_NAME
current_deploy_inventory: devnet01_edge_polygon_private
block_gas_limit: 50_000_000
block_time: 5
chain_id: 2001

```
5. Replace `vault_pass` in `local-extra-vars.yml` with the following encrypted value
```
cat password.txt | ansible-vault encrypt_string --stdin-name vault_pass --vault-password password.txt 
```
6. Replace the `--premine` values with the accounts that you want to premine in `roles/edge/templates/bootstrap.sh`. Either update the value for `loadtest_account` in `group_vars/all.yml` or replace with a new line. Format: `<address>:<balance>`. Default premined balance: `1000000000000000000000000`
```
--premine {{ loadtest_account }}:1000000000000000000000000000 \
```
6. Check if your instances are available by running the following.
```
ansible-inventory --graph
````
7. Check all your instances are reachable by ansible
```
ansible --inventory inventory/aws_ec2.yml --vault-password-file=password.txt --extra-vars "@local-extra-vars.yml" all -m ping
```
8. Run ansible playbook
```
ansible-playbook --inventory inventory/aws_ec2.yml --vault-password-file=password.txt --extra-vars "@local-extra-vars.yml" site.yml
```

## Destroy Procedure 💥
In the root directory, run `terraform destroy -auto-approve`