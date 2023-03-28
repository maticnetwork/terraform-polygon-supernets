

resource "aws_route53_zone" "private_zone" {
  name          = var.base_dn
  force_destroy = true
  vpc {
    vpc_id     = var.devnet_id
    vpc_region = var.region
  }
}
resource "aws_route53_zone" "reverse_zone" {
  name          = "in-addr.arpa"
  force_destroy = true
  vpc {
    vpc_id     =  var.devnet_id
    vpc_region = var.region
  }
}


resource "aws_route53_record" "validator_private" {
  count   = var.validator_count
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = format("validator-%03d.%s", count.index + 1, var.base_dn)
  type    = "A"
  ttl     = "60"
  records = [element(var.validator_private_ips, count.index)]
}
resource "aws_route53_record" "validator_private_reverse" {
  count   = var.validator_count
  zone_id = aws_route53_zone.reverse_zone.zone_id
  records = [format("validator-%03d.%s", count.index + 1, var.base_dn)]
  type    = "PTR"
  ttl     = "60"
  name    = join(".", reverse(split(".", element(var.validator_private_ips, count.index))))
}

resource "aws_route53_record" "fullnode_private" {
  count   = var.fullnode_count
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = format("fullnode-%03d.%s", count.index + 1, var.base_dn)
  type    = "A"
  ttl     = "60"
  records = [element(var.fullnode_private_ips, count.index)]
}
resource "aws_route53_record" "fullnode_private_reverse" {
  count   = var.fullnode_count
  zone_id = aws_route53_zone.reverse_zone.zone_id
  records = [format("fullnode-%03d.%s", count.index + 1, var.base_dn)]
  type    = "PTR"
  ttl     = "60"
  name    = join(".", reverse(split(".", element(var.fullnode_private_ips, count.index))))
}

resource "aws_route53_record" "int_rpc" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "int-rpc.${var.base_dn}"
  type    = "CNAME"
  ttl     = "60"
  records = [var.aws_lb_int_rpc_domain]
}

