output "aws_lb_domain" {
  value = aws_lb.int_rpc.dns_name
}
