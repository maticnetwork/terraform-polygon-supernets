variable "region" {
  description = "The region where we want to deploy"
  type        = string
  default     = "us-west-2"
}
variable "zones" {
  description = "The zones for deployment"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}
variable "environment" {
  description = "The environment for deployment for this particular deployment"
  type        = string
  default     = "devnet"
}
variable "deployment_name" {
  description = "The unique name for this particular deployment"
  type        = string
}
variable "owner" {
  description = "The main point of contact for this particular deployment"
  type        = string
}
variable "aws_profile" {
  description = "The AWS profile that we're going to use"
  type        = string
  default     = "default"
}

variable "company_name" {
  description = "The name of the company for this particular deployment"
  type        = number
  default     = 0
}
variable "create_ssh_key" {
  description = "Should a new ssh key be created or should we use the devnet_key_value"
  type        = bool
  default     = true
}
variable "http_rpc_port" {
  description = "The TCP port that will be used for http rpc"
  type        = number
  default     = 8545
}
variable "node_storage" {
  description = "The size of the storage disk attached to full nodes and validators"
  type        = number
  default     = 10
}
variable "base_instance_type" {
  description = "The type of instance that we're going to use"
  type        = string
  default     = "c6a.large"
}
# based on the type of network this is where we can configure the number of nodes
variable "fullnode_count" {
  description = "The number of full nodes that we're going to deploy"
  type        = number
  default     = 6
}
variable "validator_count" {
  description = "The number of validators that we're going to deploy"
  type        = number
  default     = 3
}

variable "jumpbox_count" {
  description = "The number of jump boxes that we're going to deploy"
  type        = number
  default     = 1
}

variable "private_network_mode" {
  description = "True if vms should bey default run in the private subnets"
  type        = bool
  default     = true
}
variable "devnet_vpc_block" {
  description = "The cidr block for our VPC"
  type        = string
  default     = "10.10.0.0/16"
}
# 10.10.0.0/18
variable "devnet_public_subnet" {
  description = "The cidr block for the public subnet in our VPC"
  type        = list(string)
  default     = ["10.10.0.0/22", "10.10.4.0/22", "10.10.8.0/22"]
}
# 10.10.64.0/18
variable "devnet_private_subnet" {
  description = "The cidr block for the private subnet in our VPC"
  type        = list(string)
  default     = ["10.10.64.0/22", "10.10.68.0/22", "10.10.72.0/22"]
}
variable "jumpbox_ssh_access" {
  description = "Which CIDRs should be allow to SSH into the jumpbox"
  type        = list(string)
}
variable "network_acl" {
  description = "Which CIDRs should be allowed to access the explorer and RPC"
  type        = list(string)
  default     = ["54.159.156.68/32", "34.192.184.1/32", "0.0.0.0/0"]
}
variable "devnet_key_value" {
  description = "The public key value to use for the ssh key"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA513ky/mJ4oKMKX0OFF44NPN9cqiZ5CIyYAa5l8M4Z6 jhilliard@polygon.technology"
}
variable "jumpbox_instance_type" {
  description = "The type of instance that we're going to use for the jumpbox"
  type        = string
  default     = "c6a.large"
}