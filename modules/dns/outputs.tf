output "certificate_arn" {
  value = var.route53_zone_id == "" ? "" : aws_acm_certificate.ext_rpc[0].arn
}