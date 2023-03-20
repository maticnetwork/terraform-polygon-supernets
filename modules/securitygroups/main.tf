# Default Security Group of VPC should allow all traffic that's internal
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.devnet.id
  depends_on = [
    aws_vpc.devnet
  ]

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
}

resource "aws_security_group" "all_node_instances" {
  name        = format("all-%s-%s-nodes", var.network_type, var.deployment_name)
  description = format("Configuration for the %s %s collection of instances", var.network_type, var.deployment_name)
  vpc_id      = aws_vpc.devnet.id
}
resource "aws_security_group_rule" "all_node_instances" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.all_node_instances.id
}

resource "aws_network_interface_sg_attachment" "all_node_instances" {
  count                = length(local.all_instances)
  security_group_id    = aws_security_group.all_node_instances.id
  network_interface_id = element(local.all_instances, count.index).primary_network_interface_id
}

resource "aws_security_group" "open_ssh" {
  name        = "open-ssh-access"
  description = "configuration for open ssh access"
  vpc_id      = aws_vpc.devnet.id
}
resource "aws_security_group_rule" "open_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = var.jumpbox_ssh_access
  security_group_id = aws_security_group.open_ssh.id
}
resource "aws_network_interface_sg_attachment" "open_ssh" {
  count                = var.jumpbox_count
  security_group_id    = aws_security_group.open_ssh.id
  network_interface_id = element(aws_instance.jumpbox, count.index).primary_network_interface_id
}

resource "aws_security_group" "open_rpc" {
  name        = "internal-rpc-access"
  description = "Allowing internal rpc"
  vpc_id      = aws_vpc.devnet.id
}
resource "aws_security_group_rule" "open_rpc" {
  type              = "ingress"
  from_port         = var.http_rpc_port
  to_port           = var.http_rpc_port
  protocol          = "TCP"
  cidr_blocks       = var.network_acl
  security_group_id = aws_security_group.open_rpc.id
}
resource "aws_network_interface_sg_attachment" "open_rpc" {
  count                = length(local.all_p2p_nodes)
  security_group_id    = aws_security_group.open_rpc.id
  network_interface_id = element(local.all_p2p_nodes, count.index).primary_network_interface_id
}
resource "aws_security_group_rule" "open_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = var.network_acl
  security_group_id = aws_security_group.open_http.id
}
