resource "aws_ebs_volume" "validator" {
  count             = var.validator_count
  availability_zone = element(var.zones, count.index)
  size              = var.node_storage
  type              = "gp3"
}
resource "aws_volume_attachment" "validator" {
  count       = var.validator_count
  device_name = "/dev/sdf"
  volume_id   = element(aws_ebs_volume.validator, count.index).id
  instance_id = element(var.validator_instance_ids, count.index)
}
resource "aws_ebs_volume" "fullnode" {
  count             = var.fullnode_count
  availability_zone = element(var.zones, count.index)
  size              = var.node_storage
  type              = "gp3"
}
resource "aws_volume_attachment" "fullnode" {
  count       = var.fullnode_count
  device_name = "/dev/sdf"
  volume_id   = element(aws_ebs_volume.fullnode, count.index).id
  instance_id = element(var.fullnode_instance_ids, count.index)
}
