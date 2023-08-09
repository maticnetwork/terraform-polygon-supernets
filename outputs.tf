output "aws_lb_int_rpc_domain" {
  value = module.elb.aws_lb_int_rpc_domain
}

output "aws_lb_ext_domain" {
  value = module.elb.aws_lb_ext_rpc_domain
}

output "aws_lb_ext_geth_domain" {
  value = module.elb.aws_lb_ext_rpc_geth_domain
}

output "base_dn" {
  value = local.base_dn
}
output "base_id" {
  value = local.base_id
}
output "pk_ansible" {
  value     = module.ec2.pk_ansible
  sensitive = true
}

output "geth_private_ip" {
  value = try(module.ec2.geth_private_ips[0], null)
}