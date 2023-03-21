variable "base_dn" {
  description = "Value of the base domain name to identify the resources"
  type        = string
}

variable "region" {
  description = "The region where we want to deploy"
  type        = string
  default     = "us-west-2"
}
variable "fullnode_count" {
  description = "The number of full nodes that we're going to deploy"
  type        = number
}
variable "validator_count" {
  description = "The number of validators that we're going to deploy"
  type        = number
}

variable "devnet_id" {
  type        = string
}

variable "validator_private_ips" {
  type = list(string)
}
variable "fullnode_private_ips" {
  type = list(string)
}
variable "aws_lb_domain" {
  type = string
}