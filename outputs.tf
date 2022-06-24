output "dev_server_public_ip" {
  value = aws_instance.mtc_dev.public_ip
}