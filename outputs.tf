output "aws_lb_domain" {
  value = module.elb.aws_lb_domain
}

output "base_dn" {
  value = local.base_dn
}
output "base_id" {
  value = local.base_id
}