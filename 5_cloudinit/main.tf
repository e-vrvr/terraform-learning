# Configure the AWS Provider
provider "aws" {
  region     = "us-east-1"
  access_key = 
  secret_key = 
}

locals {
  region        = "us-east-1"
  instance_type = "t2.micro"
  tags = {
    Name  = "module_vpc"
    Env   = "dev"
    Owner = "vv"
  }
}

data "aws_vpc" "my_vpc" {
  filter {
    name   = "tag:Name"
    values = ["default"]
  }
}

data "aws_internet_gateway" "my_internet_gateway" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.my_vpc.id]
  }
}

data "template_file" "userdata" {
  template = file("./userdata.yml")
}

resource "aws_instance" "web_server" {
  ami           = "ami-083654bd07b5da81d"
  instance_type = local.instance_type

  key_name = aws_key_pair.deployer.key_name

  availability_zone = "${local.region}a"
  user_data         = data.template_file.userdata.rendered
  tags              = local.tags


  network_interface {
    network_interface_id = aws_network_interface.foo.id
    device_index         = 0
  }
}


resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDRUIpA8e/sgSdyMVSEwvQNtQ1OmQ7w6DV0AjSuypI0tyAKVDkW7rnj875hzTHM3bjC2OGPMhfqojfiupIQmKs1dJAqPo1JaS0vJJWMVZG2H7wbkv1JyEcq0WHMQRCNGRiO91fMaXxxNKBehREBnX4hmelWjY31SBG3aFxgJgLPQlVLXePUEyHK16b5HbvrKZY11RFkM7tBIGoBA6KooohNVdsKdzyc70uWQKG2wZ+qePqx3/K/n4iwXiiIExZA+JVqKX9+s6Uq7hnPV77oZY3zwpGiI9ni38SQw0rXztQ0dNO+sdRZaFRbVxfZf4vFVAgat0LwsBQYDOjdg2sN63twGI3IixYWesKvAEyRqwvKuj+c3xbl0pt6tWymKNkhXPK8ZwWcEapAozt/m89MAYn2QjyTe8gCadljhUki3CrpkkHYux8jNLvfuYe4DI0m/HShop+KY8m2LfdeGcyffr04UCWyoFaKZGOEWCHtTPfgndKDzehb4EHS1F5Zwv8fEDE= nixxx@PC"
}


resource "aws_subnet" "my_subnet" {
  vpc_id                  = data.aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${local.region}a"
  map_public_ip_on_launch = true
  tags                    = local.tags
}

resource "aws_network_interface" "foo" {
  subnet_id       = aws_subnet.my_subnet.id
  private_ips     = ["10.0.2.100"]
  security_groups = [aws_security_group.allow_web.id]
  tags            = local.tags
}
resource "aws_route_table_association" "amy_route_table_association" { #asscociate the route table and subnet
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.foo.id
  associate_with_private_ip = "10.0.2.100"
  depends_on = [
    data.aws_internet_gateway.my_internet_gateway
  ]
}
resource "aws_route_table" "my_route_table" {
  vpc_id = data.aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # default route
    gateway_id = data.aws_internet_gateway.my_internet_gateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = data.aws_internet_gateway.my_internet_gateway.id
  }

  tags = {
    Name = "my_route_table"
  }
}

resource "aws_security_group" "allow_web" {
  name        = "allow_tls"
  description = "Allow Web inbound traffic"
  vpc_id      = data.aws_vpc.my_vpc.id

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

  tags = local.tags
}


resource "null_resource" "status" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    cluster_instance_ids = join(",", aws_instance.web_server.*.id)
  }

  provisioner "local-exec" { 
    command = "echo ${aws_instance.web_server.public_ip} >> public_ips.txt" 
  }
}