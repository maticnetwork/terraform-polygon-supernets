output "pk_ansible" {
  value     = tls_private_key.pk.private_key_pem
  sensitive = true
}
output "validator_private_ips" {
  value = aws_network_interface.validator_private.*.private_ip
}
output "non_validator_private_ips" {
  value = aws_network_interface.non_validator_private.*.private_ip
}

output "fullnode_private_ips" {
  value = aws_network_interface.fullnode_private.*.private_ip
}

output "geth_private_ips" {
  value = aws_network_interface.geth_private.*.private_ip
}

output "fullnode_instance_ids" {
  value = aws_instance.fullnode.*.id
}

output "validator_instance_ids" {
  value = aws_instance.validator.*.id
}
output "non_validator_instance_ids" {
  value = aws_instance.non_validator.*.id
}

output "geth_instance_ids" {
  value = aws_instance.geth.*.id
}

output "validator_primary_network_interface_ids" {
  value = aws_instance.validator.*.primary_network_interface_id
}
output "non_validator_primary_network_interface_ids" {
  value = aws_instance.non_validator.*.primary_network_interface_id
}
output "fullnode_primary_network_interface_ids" {
  value = aws_instance.fullnode.*.primary_network_interface_id
}
output "geth_primary_network_interface_ids" {
  value = aws_instance.geth.*.primary_network_interface_id
}