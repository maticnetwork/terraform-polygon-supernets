resource "aws_lb" "int_rpc" {
  name               = "int-rpc-${var.base_id}"
  load_balancer_type = "network"
  internal           = true
  subnets            = var.devnet_private_subnet_ids
}
resource "aws_lb_target_group" "int_rpc" {
  name        = "int-rpc-${var.base_id}"
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.devnet_id
  port        = var.http_rpc_port
}

resource "aws_lb_target_group_attachment" "int_rpc" {
  count            = var.fullnode_count
  target_group_arn = aws_lb_target_group.int_rpc.arn
  target_id        = element(var.fullnode_instance_ids, count.index)
  port             = var.http_rpc_port
}

resource "aws_lb_listener" "int_rpc" {
  load_balancer_arn = aws_lb.int_rpc.arn
  port              = var.http_rpc_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.int_rpc.arn
  }
}

resource "aws_lb" "ext_rpc" {
  name               = "ext-rpc-${var.base_id}"
  load_balancer_type = "application"
  internal           = false
  subnets            = var.devnet_public_subnet_ids
  security_groups    = [var.security_group_open_http_id, var.security_group_default_id]
}
resource "aws_lb_target_group" "ext_rpc" {
  name        = "ext-rpc-${var.base_id}"
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.devnet_id
  port        = var.http_rpc_port
}
resource "aws_lb_target_group_attachment" "ext_rpc" {
  count            = var.fullnode_count
  target_group_arn = aws_lb_target_group.ext_rpc.arn
  target_id        = element(var.fullnode_instance_ids, count.index)
  port             = var.http_rpc_port
}
resource "aws_lb_listener" "ext_rpc" {
  load_balancer_arn = aws_lb.ext_rpc.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ext_rpc.arn
  }
}