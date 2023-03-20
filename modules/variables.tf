variable "base_dn" {
  description = "Value of the base domain name to identify the resources"
  type        = string
}

# These variables are required to use this module
variable "deployment_name" {
  description = "The unique name for this particular deployment"
  type        = string
}
variable "owner" {
  description = "The main point of contact for this particular deployment"
  type        = string
}
variable "network_type" {
  description = "An identifier to indicate what type of network this is"
  type        = string
}

variable "http_rpc_port" {
  description = "The TCP port that will be used for http rpc"
  type        = number
  default     = 8545
}
variable "explorer_http_port" {
  description = "The HTTP Port for the block explorer"
  type        = number
  default     = 4000
}

# By default, we're going to use the us-west region with micro nodes running ubuntu
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

variable "base_ami" {
  # https://rockylinux.org/cloud-images
  # Rocky-8-ec2-8.5-20211114.2.x86_64
  description = "Value of the base AMI that we're using"
  type        = string
  default     = "ami-09ca837d91f083d04"
}

variable "base_instance_type" {
  description = "The type of instance that we're going to use"
  type        = string
  default     = "c6a.large"
}
variable "jumpbox_instance_type" {
  description = "The type of instance that we're going to use for the jumpbox"
  type        = string
  default     = "c6a.large"
}
variable "explorer_instance_type" {
  description = "The type of instance that we're going to use for the explorer nodes"
  type        = string
  default     = "c6a.2xlarge"
}

variable "devnet_key_name" {
  description = "key pair name to use for devnet"
  type        = string
}

# Keys logging into the nodes
variable "devnet_key_value" {
  description = "The public key value to use for the ssh key"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA513ky/mJ4oKMKX0OFF44NPN9cqiZ5CIyYAa5l8M4Z6 jhilliard@polygon.technology"
}
variable "create_ssh_key" {
  description = "Should a new ssh key be created or should we use the devnet_key_value"
  type        = bool
  default     = true
}
# basic networking and subnets
# 10.10.0.0/16 for the full vpc and breaking this space down into quarters for the subnets
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
