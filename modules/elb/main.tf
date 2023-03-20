resource "aws_lb" "int_rpc" {
  name               = "int-rpc-${local.base_id}"
  load_balancer_type = "network"
  internal           = true
  subnets            = [for subnet in aws_subnet.devnet_private : subnet.id]
}
resource "aws_lb_target_group" "int_rpc" {
  name        = "int-rpc-${local.base_id}"
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = aws_vpc.devnet.id
  port        = var.http_rpc_port
}

resource "aws_lb_target_group_attachment" "int_rpc" {
  count            = length(aws_instance.fullnode)
  target_group_arn = aws_lb_target_group.int_rpc.arn
  target_id        = element(aws_instance.fullnode, count.index).id
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
  name               = "ext-rpc-${local.base_id}"
  load_balancer_type = "application"
  internal           = false
  subnets            = [for subnet in aws_subnet.devnet_public : subnet.id]
  security_groups    = [aws_security_group.open_http.id, aws_default_security_group.default.id]
}
resource "aws_lb_target_group" "ext_rpc" {
  name        = "ext-rpc-${local.base_id}"
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.devnet.id
  port        = var.http_rpc_port
}
resource "aws_lb_target_group_attachment" "ext_rpc" {
  count            = var.fullnode_count
  target_group_arn = aws_lb_target_group.ext_rpc.arn
  target_id        = element(aws_instance.fullnode, count.index).id
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