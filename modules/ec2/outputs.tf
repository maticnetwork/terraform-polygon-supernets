output "pk_ansible" {
  value     = tls_private_key.pk.private_key_pem
  sensitive = true
}
variable "private_network_mode" {
  description = "True if vms should bey default run in the private subnets"
  type        = bool
  default     = true
}