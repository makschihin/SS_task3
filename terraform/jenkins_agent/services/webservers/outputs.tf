output "public_dns" {
  value       = module.webservers.public_dns
  description = "The domain name of the load balancer"
}

