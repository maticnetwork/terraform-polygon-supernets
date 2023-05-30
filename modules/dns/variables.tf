variable "base_dn" {
  description = "Value of the base domain name to identify the resources"
  type        = string
}

variable "region" {
  description = "The region where we want to deploy"
  type        = string
  default     = "us-west-2"
}

variable "deployment_name" {
  description = "The unique name for this particular deployment"
  type        = string
}

variable "fullnode_count" {
  description = "The number of full nodes that we're going to deploy"
  type        = number
}
variable "validator_count" {
  description = "The number of validators that we're going to deploy"
  type        = number
}
variable "non_validator_count" {
  description = "The number of non-validators that we're going to deploy"
  type        = number
}
variable "geth_count" {
  description = "The number of geth that we're going to deploy"
  type        = number
}

variable "devnet_id" {
  type = string
}

variable "validator_private_ips" {
  type = list(string)
}
variable "non_validator_private_ips" {
  type = list(string)
}
variable "fullnode_private_ips" {
  type = list(string)
}
variable "geth_private_ips" {
  type = list(string)
}
variable "aws_lb_int_rpc_domain" {
  type = string
}
variable "aws_lb_ext_rpc_geth_domain" {
  type = string
}

variable "route53_zone_id" {
  description = "The ID for external DNS"
  type        = string
}