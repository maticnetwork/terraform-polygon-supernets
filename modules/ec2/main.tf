# allow ansible to connect with ec2 instances via ssh
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  devnet_key_name = "${var.base_devnet_key_name}-${var.deployment_name}-${var.network_type}"
  secret_name     = "${var.deployment_name}-${var.network_type}"
  # Use this for domains / url compatibility
  # base_dn = format("%s.%s.polygon.private", var.deployment_name, var.network_type)
  # Us this for names that don't allow dots and aren't part of a url
}

resource "aws_key_pair" "devnet" {
  key_name   = local.devnet_key_name
  public_key = var.create_ssh_key ? tls_private_key.pk.public_key_openssh : var.devnet_key_value
}

resource "aws_secretsmanager_secret" "devnet" {
  name = local.secret_name
}

resource "aws_secretsmanager_secret_version" "devnet" {
  secret_id     = aws_secretsmanager_secret.devnet.id
  secret_string = tls_private_key.pk.private_key_pem
}

resource "aws_network_interface" "validator_private" {
  count     = var.validator_count
  subnet_id = element(var.private_network_mode ? var.devnet_private_subnet_ids : var.devnet_public_subnet_ids, count.index)

  tags = {
    Name = format("validator-private-%03d.%s", count.index + 1, var.base_dn)
  }
}

resource "aws_network_interface" "non_validator_private" {
  count     = var.non_validator_count
  subnet_id = element(var.private_network_mode ? var.devnet_private_subnet_ids : var.devnet_public_subnet_ids, count.index)

  tags = {
    Name = format("non-validator-private-%03d.%s", count.index + 1, var.base_dn)
  }
}

resource "aws_network_interface" "fullnode_private" {
  count     = var.fullnode_count
  subnet_id = element(var.private_network_mode ? var.devnet_private_subnet_ids : var.devnet_public_subnet_ids, count.index)

  tags = {
    Name = format("fullnode-private-%03d.%s", count.index + 1, var.base_dn)
  }
}
resource "aws_network_interface" "geth_private" {
  count     = var.geth_count
  subnet_id = element(var.private_network_mode ? var.devnet_private_subnet_ids : var.devnet_public_subnet_ids, count.index)

  tags = {
    Name = format("geth-private-%03d.%s", count.index + 1, var.base_dn)
  }
}

resource "aws_instance" "validator" {
  ami                  = var.base_ami
  instance_type        = var.base_instance_type
  count                = var.validator_count
  key_name             = aws_key_pair.devnet.key_name
  iam_instance_profile = var.ec2_profile_name

  root_block_device {
    delete_on_termination = true
    volume_size           = 30
    volume_type           = "gp2"
  }

  network_interface {
    network_interface_id = element(aws_network_interface.validator_private, count.index).id
    device_index         = 0
  }

  tags = {
    Name     = format("validator-%03d.%s", count.index + 1, var.base_dn)
    Hostname = format("validator-%03d", count.index + 1)
    Role     = "validator"
  }
}

resource "aws_instance" "non_validator" {
  ami                  = var.base_ami
  instance_type        = var.base_instance_type
  count                = var.non_validator_count
  key_name             = aws_key_pair.devnet.key_name
  iam_instance_profile = var.ec2_profile_name

  root_block_device {
    delete_on_termination = true
    volume_size           = 30
    volume_type           = "gp2"
  }

  network_interface {
    network_interface_id = element(aws_network_interface.non_validator_private, count.index).id
    device_index         = 0
  }

  tags = {
    Name     = format("non-validator-%03d.%s", count.index + 1, var.base_dn)
    Hostname = format("non-validator-%03d", count.index + 1)
    Role     = "non-validator"
  }
}

resource "aws_instance" "fullnode" {
  ami                  = var.base_ami
  instance_type        = var.base_instance_type
  count                = var.fullnode_count
  key_name             = aws_key_pair.devnet.key_name
  iam_instance_profile = var.ec2_profile_name

  root_block_device {
    delete_on_termination = true
    volume_size           = 30
    volume_type           = "gp2"
  }
  network_interface {
    network_interface_id = element(aws_network_interface.fullnode_private, count.index).id
    device_index         = 0
  }

  tags = {
    Name     = format("fullnode-%03d.%s", count.index + 1, var.base_dn)
    Hostname = format("fullnode-%03d", count.index + 1)
    Role     = "fullnode"
  }
}

resource "aws_instance" "geth" {
  ami                  = var.base_ami
  instance_type        = var.base_instance_type
  count                = var.geth_count
  key_name             = aws_key_pair.devnet.key_name
  iam_instance_profile = var.ec2_profile_name

  root_block_device {
    delete_on_termination = true
    volume_size           = 30
    volume_type           = "gp2"
  }

  network_interface {
    network_interface_id = element(aws_network_interface.geth_private, count.index).id
    device_index         = 0
  }

  tags = {
    Name     = format("geth-%03d.%s", count.index + 1, var.base_dn)
    Hostname = format("geth-%03d", count.index + 1)
    Role     = "geth"
  }
}