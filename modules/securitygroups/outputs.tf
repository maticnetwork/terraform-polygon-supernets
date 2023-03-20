output "security_group_open_http_id" {
  value = aws_security_group.open_http.id
}
output "security_group_default_id" {
  value = aws_default_security_group.default.id
}