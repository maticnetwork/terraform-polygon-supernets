variable "http_rpc_port" {
  description = "The TCP port that will be used for http rpc"
  type        = number
}
variable "fullnode_count" {
  description = "The number of full nodes that we're going to deploy"
  type        = number
}
variable "validator_count" {
  description = "The number of validators that we're going to deploy"
  type        = number
}

variable "devnet_private_subnet_ids" {
  type        = list(string)
}
variable "devnet_public_subnet_ids" {
  type        = list(string)
}

variable "fullnode_instance_ids" {
  type = list(string)
}
variable "validator_instance_ids" {
  type = list(string)
}
variable "devnet_id" {
  type = string
}
variable "base_id" {
  type = string
}
variable "security_group_open_http_id" {
  type = string
}
variable "security_group_default_id" {
  type = string
}