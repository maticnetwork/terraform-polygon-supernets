variable "base_dn" {
  description = "Value of the base domain name to identify the resources"
  type        = string
}
variable "base_instance_type" {
  description = "The type of instance that we're going to use"
  type        = string
}
variable "base_ami" {
  description = "Value of the base AMI that we're using"
  type        = string
  default     = "ami-0ecc74eca1d66d8a6"
}
variable "fullnode_count" {
  description = "The number of full nodes that we're going to deploy"
  type        = number
}
variable "validator_count" {
  description = "The number of validators that we're going to deploy"
  type        = number
}

variable "jumpbox_count" {
  description = "The number of jump boxes that we're going to deploy"
  type        = number
}
variable "private_network_mode" {
  description = "True if vms should bey default run in the private subnets"
  type        = bool
}
variable "base_devnet_key_name" {
  description = "base key pair name to use for devnet"
  type        = string
}
variable "deployment_name" {
  description = "The unique name for this particular deployment"
  type        = string
}
variable "network_type" {
  description = "An identifier to indicate what type of network this is"
  type        = string
}
variable "create_ssh_key" {
  description = "Should a new ssh key be created or should we use the devnet_key_value"
  type        = bool
}
variable "devnet_key_value" {
  description = "The public key value to use for the ssh key"
  type        = string
}

variable "devnet_private_subnet_ids" {
  type = list(string)
}
variable "devnet_public_subnet_ids" {
  type = list(string)
}

variable "ec2_profile_name" {
  type = string
}
variable "jumpbox_instance_type" {
  description = "The type of instance that we're going to use for the jumpbox"
  type        = string
}
