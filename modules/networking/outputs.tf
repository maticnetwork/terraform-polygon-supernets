output "devnet_public_subnet_ids" {
  value = aws_subnet.devnet_public.*.id
}
output "devnet_private_subnet_ids" {
  value = aws_subnet.devnet_private.*.id
}
output "devnet_id" {
  value = aws_vpc.devnet.id
}
