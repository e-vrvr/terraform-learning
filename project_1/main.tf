terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = 
  secret_key = 
}

locals {
  name_prefix = upper("my")
}

resource "aws_vpc" "my_first_private_cloud" { # name within Terraform
  cidr_block       = "10.0.0.0/16"

  #tags = var.my_object
  tags = {
    Name = "my_first_private_cloud" # name within AWS
  }
}

resource "aws_internet_gateway" "my_internet_gateway" {
  vpc_id = aws_vpc.my_first_private_cloud.id

  tags = {
    Name = "${local.name_prefix}_internet_gateway" # we interpolate string here because it is within the string
#    arr = var.my_array
  }
}

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_first_private_cloud.id

  route {
    cidr_block = var.cidr # default route
    gateway_id = aws_internet_gateway.my_internet_gateway.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.my_internet_gateway.id
  }

  tags = {
    Name = "my_route_table"
  }
}

resource "aws_subnet" "subnet_1" {
  vpc_id     = aws_vpc.my_first_private_cloud.id # takes the id of VPS above
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a" #data center

  tags = {
    Name = "my_first_subnet"
  }
}

resource "aws_route_table_association" "amy_route_table_association" { #asscociate the route table and subnet
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_tls"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.my_first_private_cloud.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

resource "aws_network_interface" "tesweb_server" {
  subnet_id       = aws_subnet.subnet_1.id
  private_ips     = ["10.0.1.50"] # private IP to be used
  security_groups = [aws_security_group.allow_web.id]
}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.tesweb_server.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [
    aws_internet_gateway.my_internet_gateway
  ]
}

# Outputs the value of variable to the console after calling 'terraform apply', 
# or 'terraform output', 'terraform output server_public_ip'.
# A common practice is to keep the output definitions in the outputs.tf file
output "server_public_ip" {
  value = aws_eip.one.public_ip
}

resource "aws_instance" "web_server" {
  ami           = "ami-083654bd07b5da81d"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "my_terraform_key"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.tesweb_server.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo your very first web server > /var/www/html/index.html'
              EOF

  tags = {
    Name = "HelloWorld"
    instance_no = 1
  }
}