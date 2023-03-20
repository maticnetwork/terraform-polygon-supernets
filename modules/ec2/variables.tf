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
variable "metrics_count" {
  description = "The number of boxes that can be used local monitoring"
  type        = number
}
variable "private_network_mode" {
  description = "True if vms should bey default run in the private subnets"
  type        = bool
  default     = true
}
variable "base_devnet_key_name" {
  description = "base key pair name to use for devnet"
  type        = string
}