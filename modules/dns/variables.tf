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
variable "metrics_count" {
  description = "The number of boxes that can be used local monitoring"
  type        = number
}