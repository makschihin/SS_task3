#############################################################################
# Create VPC
#############################################################################
resource "aws_vpc" "jenkins-vpc" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_support   = "true" #gives you an internal domain name
    enable_dns_hostnames = "true" #gives you an internal host name
    enable_classiclink   = "false"
    instance_tenancy     = "default"    
    
    tags = {
        Name = "jenkins-vpc"
    }
}

#############################################################################
# Create Public subnet
#############################################################################
resource "aws_subnet" "jenkins-public-1" {
    vpc_id = aws_vpc.jenkins-vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "us-east-2a"

    tags = {
        Name = "jenkins-public-1"
    }
}

#############################################################################
# Create Internet Gateway
#############################################################################
resource "aws_internet_gateway" "jenkins-igw" {
    vpc_id = aws_vpc.jenkins-vpc.id

    tags = {
        Name = "jenkins-igw"
    }
}

#############################################################################
# Create Route Table
#############################################################################
resource "aws_route_table" "jenkins-public-crt" {
    vpc_id = aws_vpc.jenkins-vpc.id
    
    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0" 
        //CRT uses this IGW to reach internet
        gateway_id = aws_internet_gateway.jenkins-igw.id
      }
    
    tags = {
        Name = "jenkins-public-crt"
    }
}

#############################################################################
# Assosiate Subnet with Route Table
#############################################################################
resource "aws_route_table_association" "jenkins-crta-public-subnet-1"{
    subnet_id = aws_subnet.jenkins-public-1.id
    route_table_id = aws_route_table.jenkins-public-crt.id
}