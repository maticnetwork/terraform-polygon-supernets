output "aws_lb_int_rpc_domain" {
  value = aws_lb.int_rpc.dns_name
}

output "aws_lb_ext_rpc_domain" {
  value = aws_lb.ext_rpc.dns_name
}
output "aws_lb_ext_rpc_validator_domain" {
  value = aws_lb.ext_rpc_validator.dns_name
}