locals {
  # region             = "us-west-2"
  # zones              = ["us-west-2a", "us-west-2b", "us-west-2c"]
  # environment        = "devnet"
  # deployment_name    = "devnet06"
  # owner              = "jhilliard@polygon.technology"
  network_type       = "edge"
  # aws_profile        = "AWSAdministratorAccess-937573258486"
  # base_instance_type = "c6a.2xlarge"
  base_ami           = "ami-0ecc74eca1d66d8a6"
  # fullnode_count     = 3
  # validator_count    = 4
  # jumpbox_count      = 1
  # metrics_count      = 1
  base_dn            = format("%s.%s.%s.private", var.deployment_name, local.network_type, var.company_name)
  # create_ssh_key     = false
  # http_rpc_port      = 10002
  # node_storage       = 10
  base_id = format("%s-%s", var.deployment_name, local.network_type)
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.58.0"
    }
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.22.0"
    }
  }
  required_version = ">= 1.2.0"
}

module "edge" {
  source                       = "../modules"
  deployment_name              = var.deployment_name
  owner                        = var.owner
  network_type                 = local.network_type
  aws_profile                  = var.aws_profile
  region                       = var.region
  zones                        = var.zones
  base_instance_type           = var.base_instance_type
  base_ami                     = local.base_ami
  base_dn                      = local.base_dn
  base_devnet_key_name              = format("%s_ssh_key", var.deployment_name)
  fullnode_count               = var.fullnode_count
  validator_count              = var.validator_count
  jumpbox_count                = var.jumpbox_count
  metrics_count                = var.metrics_count
  create_ssh_key               = var.create_ssh_key
  http_rpc_port                = var.http_rpc_port
  node_storage                 = var.node_storage
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment    = var.environment
      Network        = local.network_type
      Owner          = var.owner
      DeploymentName = var.deployment_name
      BaseDN         = local.base_dn
      Name           = local.base_dn
    }
  }
}