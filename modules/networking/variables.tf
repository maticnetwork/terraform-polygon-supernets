variable "base_dn" {
  description = "Value of the base domain name to identify the resources"
  type        = string
}

# basic networking and subnets
# 10.10.0.0/16 for the full vpc and breaking this space down into quarters for the subnets
variable "devnet_vpc_block" {
  description = "The cidr block for our VPC"
  type        = string
}
# 10.10.0.0/18
variable "devnet_public_subnet" {
  description = "The cidr block for the public subnet in our VPC"
  type        = list(string)
}
# 10.10.64.0/18
variable "devnet_private_subnet" {
  description = "The cidr block for the private subnet in our VPC"
  type        = list(string)
}

variable "zones" {
  description = "The zones for deployment"
  type        = list(string)
}