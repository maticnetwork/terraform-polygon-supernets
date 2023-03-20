

resource "aws_route53_zone" "private_zone" {
  name          = var.base_dn
  force_destroy = true
  vpc {
    vpc_id     = aws_vpc.devnet.id
    vpc_region = var.region
  }
}
resource "aws_route53_zone" "reverse_zone" {
  name          = "in-addr.arpa"
  force_destroy = true
  vpc {
    vpc_id     = aws_vpc.devnet.id
    vpc_region = var.region
  }
}


resource "aws_route53_record" "validator_private" {
  count   = var.validator_count
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = format("validator-%03d.%s", count.index + 1, var.base_dn)
  type    = "A"
  ttl     = "60"
  records = [element(aws_network_interface.validator_private, count.index).private_ip]
}
resource "aws_route53_record" "validator_private_reverse" {
  count   = var.validator_count
  zone_id = aws_route53_zone.reverse_zone.zone_id
  records = [format("validator-%03d.%s", count.index + 1, var.base_dn)]
  type    = "PTR"
  ttl     = "60"
  name    = join(".", reverse(split(".", element(aws_network_interface.validator_private, count.index).private_ip)))
}

resource "aws_route53_record" "fullnode_private" {
  count   = var.fullnode_count
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = format("fullnode-%03d.%s", count.index + 1, var.base_dn)
  type    = "A"
  ttl     = "60"
  records = [element(aws_network_interface.fullnode_private, count.index).private_ip]
}
resource "aws_route53_record" "fullnode_private_reverse" {
  count   = var.fullnode_count
  zone_id = aws_route53_zone.reverse_zone.zone_id
  records = [format("fullnode-%03d.%s", count.index + 1, var.base_dn)]
  type    = "PTR"
  ttl     = "60"
  name    = join(".", reverse(split(".", element(aws_network_interface.fullnode_private, count.index).private_ip)))
}
resource "aws_route53_record" "metrics_private" {
  count   = var.metrics_count
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = format("metrics-%03d.%s", count.index + 1, var.base_dn)
  type    = "A"
  ttl     = "60"
  records = [element(aws_instance.metrics, count.index).private_ip]
}
resource "aws_route53_record" "metrics_private_reverse" {
  count   = var.metrics_count
  zone_id = aws_route53_zone.reverse_zone.zone_id
  records = [format("metrics-%03d.%s", count.index + 1, var.base_dn)]
  type    = "PTR"
  ttl     = "60"
  name    = join(".", reverse(split(".", element(aws_instance.metrics, count.index).private_ip)))
}

resource "aws_route53_record" "int_rpc" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "int-rpc.${var.base_dn}"
  type    = "CNAME"
  ttl     = "60"
  records = [aws_lb.int_rpc.dns_name]
}
resource "aws_route53_record" "explorer" {
  count   = var.explorer_count > 0 ? 1 : 0
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "explorer-db.${var.base_dn}"
  type    = "CNAME"
  ttl     = "60"
  records = [for clus in aws_rds_cluster.explorer : clus.endpoint]
}


