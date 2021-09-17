###############################
# Credentials aws
###############################
variable "access_key" {
     description = "Access key to AWS console"
     
}

variable "secret_key" {
     description = "Secret key to AWS console"
     
}

###############################
# Authtorizaciont via ssh key
###############################
variable "public_key_path" {
  description = "Public key path"
  default = "~/.ssh/test.pub"
}

variable "server_port" {
  description = "The port the web server will be listening"
  type        = number
  default     = 8080
}

variable "ssh_server_port" {
  description = "The port to ssh server"
  type        = number
  default     = 22
}

variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  type        = string
  default     = "web-test"
}

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g. t2.micro)"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "The key name for SSH to the instance"
  type        = string
  default     = ""
}

variable "user_data" {
  description = "The user data to provide when launching the instance"
  default     = ""
}