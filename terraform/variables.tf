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

variable "enable_dns_support" {
  default = true
}

variable "enable_dns_hostnames" {
  default = true
}

variable "test_vpc_cidr" {
  description = "VPC cidr"
}

variable "public_subnet" {
  description = "Public Subnets"
}

variable "private_subnet_1" {
  description = "Private Subnets"
}

variable "private_subnet_2" {
  description = "Private Subnets"
}

variable "private1_az" {
  description = "availability_zone_1"
}

variable "private2_az" {
  description = "availability_zone_2"
}
variable "db_port" {
  description = "DB port"
  type        = number
  default     = 3306
}

variable "rds_type" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"  
}

variable "rds_engine" {
  description = "RDS engine"
  default     = "mysql"
}

variable "rds_engine_version" {
  description = "RDS engine version"
  default     = "5.7"
}

variable "rds_user" {
  description = "RDS user name"
}

variable "rds_db_name" {
  description = "RDS DB name"
}

variable "rds_user_password" {
  description = "RDS user password"
}

variable "elb_port" {
  description = "The port the elb will be listening"
  type        = number
  default     = 8080
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

variable "public_key_path" {
  description = "Public key path for SSH to the instance"
  type        = string
  default     = "~/.ssh/demo2_home.pub"
}

variable "user_data" {
  description = "The user data to provide when launching the instance"
  default     = ""
}

variable "min_size" {
  description = "The minimum number of EC2 Instances in the ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "The maximum number of EC2 Instances in the ASG"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "The desired number of EC2 Instances in the ASG"
  type        = number
  default     = 2
}