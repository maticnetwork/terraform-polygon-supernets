data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "available" {
  most_recent = true
  name_regex  = ".*ubuntu-jammy-22.04-amd64-server-2023\\d{4}"
  owners      = ["099720109477"]

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
