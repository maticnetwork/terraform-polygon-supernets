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