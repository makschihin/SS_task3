output "public_dns" {
  value       = aws_instance.ubuntu_instance.public_dns
  description = "The domain name of the load balancer"
}