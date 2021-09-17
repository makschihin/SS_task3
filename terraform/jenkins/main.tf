#############################################################################
# Region in which we are creating infrastructure
#############################################################################
provider "aws" {
  region = "us-east-2"
}

#############################################################################
# Get latest ami 
#############################################################################
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-202104*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

#############################################################################
# Configuration for new instance
#############################################################################
resource "aws_instance" "ubuntu_instance_1" {
  ami                    = data.aws_ami.ubuntu.id
  subnet_id              = aws_subnet.jenkins-public-1.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.http.id, aws_security_group.ssh.id]
  key_name               = aws_key_pair.ec2key.key_name
  user_data              = file("./files/user_data.sh")
  tags = {
    Name      = "${var.instance_name_1}"

  }
}

resource "aws_instance" "ubuntu_instance_2" {
  ami                    = data.aws_ami.ubuntu.id
  subnet_id              = aws_subnet.jenkins-public-1.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.http.id, aws_security_group.ssh.id]
  key_name               = aws_key_pair.ec2key.key_name
  user_data              = file("./files/user_data2.sh")
  tags = {
    Name      = "${var.instance_name_2}"

  }
}
#############################################################################
# Security group server (http listen port)
#############################################################################
resource "aws_security_group" "http" {
  name = "${var.instance_name_1}-http-sg"
  vpc_id = aws_vpc.jenkins-vpc.id
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#############################################################################
# Security group server (ssh listen port)
#############################################################################
resource "aws_security_group" "ssh" {
  name = "${var.instance_name_1}-ssh-sg"
  vpc_id = aws_vpc.jenkins-vpc.id
  ingress {
    from_port   = var.ssh_server_port
    to_port     = var.ssh_server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

#############################
# Create ssh key
#############################
resource "aws_key_pair" "ec2key" {
  key_name = "publicKey"
  public_key = file(var.public_key_path)

}