output "instance_id" {
  value = aws_instance.devbox.id
}

output "public_dns" {
  value = aws_instance.devbox.public_dns
}
