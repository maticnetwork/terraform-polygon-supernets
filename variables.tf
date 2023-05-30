variable "aws_profile" {
  description = "The AWS profile that we're going to use"
  type        = string
  default     = "default"
}

variable "base_instance_type" {
  description = "The type of instance that we're going to use"
  type        = string
  default     = "c6a.large"
}

variable "company_name" {
  description = "The name of the company for this particular deployment"
  type        = string
  default     = "company"
}

variable "create_ssh_key" {
  description = "Should a new ssh key be created or should we use the devnet_key_value"
  type        = bool
  default     = true
}

variable "deployment_name" {
  description = "The unique name for this particular deployment"
  type        = string
  default     = "k1dev"
}

variable "devnet_key_value" {
  description = "The public key value to use for the ssh key. Required when create_ssh_key is false"
  type        = string
  default     = ""
}

variable "devnet_private_subnet" {
  description = "The cidr block for the private subnet in our VPC"
  type        = list(string)
  default     = ["10.10.64.0/22", "10.10.68.0/22", "10.10.72.0/22", "10.10.76.0/22"]
}

variable "devnet_public_subnet" {
  description = "The cidr block for the public subnet in our VPC"
  type        = list(string)
  default     = ["10.10.0.0/22", "10.10.4.0/22", "10.10.8.0/22", "10.10.12.0/22"]
}

variable "devnet_vpc_block" {
  description = "The cidr block for our VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "environment" {
  description = "The environment for deployment for this particular deployment"
  type        = string
  default     = "devnet"
}

variable "fullnode_count" {
  description = "The number of full nodes that we're going to deploy"
  type        = number
  default     = 0
}

variable "geth_count" {
  description = "The number of geth nodes that we're going to deploy"
  type        = number
  default     = 1
  validation {
    condition = (
      var.geth_count == 0 || var.geth_count == 1
    )
    error_message = "There should only be 1 geth node, or none (if you are using another public L1 chain for bridge)."
  }
}

variable "http_rpc_port" {
  description = "The TCP port that will be used for http rpc"
  type        = number
  default     = 10002
}

variable "network_acl" {
  description = "Which CIDRs should be allowed to access the explorer and RPC"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_storage" {
  description = "The size of the storage disk attached to full nodes ,validators and non-validators "
  type        = number
  default     = 10
}

variable "rootchain_rpc_port" {
  description = "The TCP port that will be used for rootchain (for bridge)"
  type        = number
  default     = 8545
}

variable "route53_zone_id" {
  description = "The ID of the hosted zone to contain the CNAME record to our LB"
  type        = string
  default     = ""
}

variable "owner" {
  description = "The main point of contact for this particular deployment"
  type        = string
  default     = "user@email.com"
}

variable "private_network_mode" {
  description = "True if vms should bey default run in the private subnets"
  type        = bool
  default     = true
}

variable "region" {
  description = "The region where we want to deploy"
  type        = string
  default     = "us-west-2"
}

variable "validator_count" {
  description = "The number of validators that we're going to deploy"
  type        = number
  default     = 4
}

variable "non_validator_count" {
  description = "The number of non-validators that we're going to deploy"
  type        = number
  default     = 1
}

variable "zones" {
  description = "The availability zones for deployment"
  type        = list(string)
  default     = []
}

variable "base_ami" {
  description = "The availability zones for deployment"
  type        = string
  default     = ""
}