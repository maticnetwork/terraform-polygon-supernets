variable "fullnode_count" {
  description = "The number of full nodes that we're going to deploy"
  type        = number
}
variable "validator_count" {
  description = "The number of validators that we're going to deploy"
  type        = number
}
variable "zones" {
  description = "The zones for deployment"
  type        = list(string)
}
variable "node_storage" {
  description = "The size of the storage disk attached to full nodes and validators"
  type        = number
}

variable "validator_instance_ids" {
  type        = list(string)
}
variable "fullnode_instance_ids" {
  type        = list(string)
  }