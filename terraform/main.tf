data "aws_availability_zones" "all" {}

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
# VPC
#############################################################################
resource "aws_vpc" "test_vpc" {
  cidr_block           = var.test_vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
}

# Internet Gateway
resource "aws_internet_gateway" "test_igw" {
  vpc_id = aws_vpc.test_vpc.id
}

# Public subnets
resource "aws_subnet" "public_sub" {
  vpc_id     = aws_vpc.test_vpc.id
  cidr_block = var.public_subnet
}

# Privat subnets
resource "aws_subnet" "private_sub_1" {
  vpc_id            = aws_vpc.test_vpc.id
  cidr_block        = var.private_subnet_1
  availability_zone = var.private1_az
}

resource "aws_subnet" "private_sub_2" {
  vpc_id            = aws_vpc.test_vpc.id
  cidr_block        = var.private_subnet_2
  availability_zone = var.private2_az
}

# Route table for Public Subnets
resource "aws_route_table" "publicRT" {
  vpc_id = aws_vpc.test_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test_igw.id
  } 
}

# Route table for Private Subnets
resource "aws_route_table" "privateRT" {
  vpc_id = aws_vpc.test_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NATgw.id
  }
}

# Route table association with Public Subnets
resource "aws_route_table_association" "PublicRTassociation" {
  subnet_id      = aws_subnet.public_sub.id
  route_table_id = aws_route_table.publicRT.id
}

# Route table association with Private Subnets
resource "aws_route_table_association" "PrivateRTassociation_1" {
  subnet_id      = aws_subnet.private_sub_1.id
  route_table_id = aws_route_table.privateRT.id
}

resource "aws_route_table_association" "PrivateRTassociation_2" {
  subnet_id      = aws_subnet.private_sub_2.id
  route_table_id = aws_route_table.privateRT.id
}

#############################################################################
# NAT
#############################################################################
resource "aws_eip" "nateIP" {
  vpc   = true
 }
# Creating the NAT Gateway using subnet_id
resource "aws_nat_gateway" "NATgw" {
  allocation_id = aws_eip.nateIP.id
  subnet_id     = aws_subnet.public_sub.id
}

#############################################################################
# Security groups for app
#############################################################################
# HTTP
resource "aws_security_group" "http" {
  name = "${var.cluster_name}-http-sg"
  vpc_id = aws_vpc.test_vpc.id
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

# SSH
resource "aws_security_group" "ssh" {
  name = "${var.cluster_name}-ssh-sg"
  vpc_id = aws_vpc.test_vpc.id
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

#############################################################################
# Security group server (load balancer listen port)
#############################################################################

resource "aws_security_group" "elb-sg" {
  name = "${var.cluster_name}-elb-sg"
  vpc_id = aws_vpc.test_vpc.id


  ingress {
    from_port   = var.elb_port
    to_port     = var.elb_port
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
# Security group server (load balancer listen port)
#############################################################################
resource "aws_security_group" "service-sg" {
  vpc_id = aws_vpc.test_vpc.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.elb-sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

#############################################################################
# Create cluste and cloudwatch group
#############################################################################
resource "aws_ecs_cluster" "test_cluster" {
  name = "test"
}

resource "aws_cloudwatch_log_group" "logs" {
  name = "cloudwatch-log"
}

resource "aws_ecs_task_definition" "test_task" {
  family = "task"

  container_definitions = <<DEFINITION
  [
    {
      "name": "container",
      "image": "324933475859.dkr.ecr.us-east-2.amazonaws.com/test-petclinic-image:latest",
      "entryPoint": [],
      "environment": [
        {
      "name": "MY_MYSQL_URL",
      "value": "${aws_db_instance.default.endpoint}"
        }
      ],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.logs.id}",
          "awslogs-region": "us-east-2",
          "awslogs-stream-prefix": "web-logs"
        }
      },
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 8080
        }
      ],
      "cpu": 256,
      "memory": 512,
      "networkMode": "awsvpc"
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "1024"
  cpu                      = "512"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn
}

data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.test_task.family
  depends_on = [ aws_ecs_task_definition.test_task ]
}

resource "aws_ecs_service" "ecs_service" {
  name                 = "ecs-service"
  cluster              = aws_ecs_cluster.test_cluster.id
  task_definition      = "${aws_ecs_task_definition.test_task.family}:${max(aws_ecs_task_definition.test_task.revision, data.aws_ecs_task_definition.main.revision)}"
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    subnets          = [aws_subnet.public_sub.id]
    assign_public_ip = true
    security_groups = [
      aws_security_group.service-sg.id,
      aws_security_group.elb-sg.id
    ]
  }

  load_balancer {
    target_group_arn = aws_elb.sample.arn
    container_name   = "container"
    container_port   = 8080
  }

  depends_on = [
    aws_elb.sample
  ]
}


#############################################################################
#Autoscaling_group
#############################################################################
resource "aws_appautoscaling_target" "asg_ecs" {
  max_capacity       = var.max_size
  min_capacity       = var.min_size
  resource_id        = "sevice/${aws_ecs_cluster.test_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "test"
}

resource "aws_appautoscaling_policy" "mem_asg_policy" {
  name               = "mem-asg"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.asg_ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.asg_ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.asg_ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 75
  }
}

resource "aws_appautoscaling_policy" "cpu_asg_policy" {
  name               = "cpu-asg"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.asg_ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.asg_ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.asg_ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 85
  }
}

#############################################################################
# Load balancer
#############################################################################
resource "aws_elb" "sample" {
  name               = "${var.cluster_name}-asg-elb"
  security_groups    = [aws_security_group.elb-sg.id]
  subnets            = [aws_subnet.public_sub.id]
  health_check {
    target              = "HTTP:${var.server_port}/"
    interval            = 300
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  listener {
    lb_port           = var.elb_port
    lb_protocol       = "http"
    instance_port     = var.server_port
    instance_protocol = "http"
  }
}

#############################################################################
# IAM Role
#############################################################################
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "execution-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

#############################################################################
# RDS
#############################################################################
# DB subnet group
resource "aws_db_subnet_group" "testRDS" {
  name = "testrds"
  subnet_ids = [aws_subnet.private_sub_1.id, aws_subnet.private_sub_2.id]
}

resource "aws_security_group" "rds-sg" {
  name        = "rds-security-group"
  description = "allow inbound access to the database"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    // protocol    = "tcp"
    // from_port   = 0
    // to_port     = 3306
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS instance
resource "aws_db_instance" "default" {
allocated_storage    = 10
identifier           = "sampleinstance"
storage_type         = "gp2"
engine               = var.rds_engine
engine_version       = var.rds_engine_version
instance_class       = var.rds_type
name                 = var.rds_db_name
username             = var.rds_user
password             = var.rds_user_password
port                 = var.db_port
parameter_group_name = "default.mysql5.7"
db_subnet_group_name = aws_db_subnet_group.testRDS.name
vpc_security_group_ids = [ aws_security_group.rds-sg.id ]
publicly_accessible  = false
skip_final_snapshot  = true
multi_az             = false
}

#############################
# Create ssh key
#############################
resource "aws_key_pair" "ec2key" {
  key_name = "publicKey"
  public_key = file(var.public_key_path)
}