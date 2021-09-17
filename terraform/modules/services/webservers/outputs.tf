output "public_dns_master" {
  value       = aws_instance.ubuntu_instance_1.public_dns
  description = "The domain name"
}
output "public_dns_agent" {
  value       = aws_instance.ubuntu_instance_2.public_dns
  description = "The domain name"
}