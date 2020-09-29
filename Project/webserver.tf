provider "aws" {
  region = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_access_key
}


#aws_access_keys_variables
variable aws_access_key {
  type = string
  description = "aws access key"
}

#aws_access_keys_variables
variable aws_secret_access_key {
  type = string
  description = "aws secret access key"
}


#create vpc
resource "aws_vpc" "prod-vpc"{
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "production"
    }
}

#create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
}

#create custom route table.
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod"
  }
}

#creating a variable
variable "subnet_prefix" {
  description = "cidr block for the subnet"
}

#create a subnet1
resource "aws_subnet" "subnet-1" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = var.subnet_prefix[0]
    availability_zone = "us-east-1a"
    tags = {
        Name = "prod-subnet"
    }
}

#create a subnet2
resource "aws_subnet" "subnet-2" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = var.subnet_prefix[1]
    availability_zone = "us-east-1a"
    tags = {
        Name = "dev-subnet"
    }
}

#Associate subnet with the route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

#Create security group to allow port 22(ssh), 80(http), 443(https)
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #egress protocol = -1 indicates any protocol

  tags = {
    Name = "allow_web"
  }
}

#Create a Network Interface with an IP in the subnet that was created in step 4.
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

#Assign a Elastic IP to the network interface created above
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}
#depends_on is used when there is a dependency that needs to be present

#Create a ubuntu server and install apache2
resource "aws_instance" "web-server-instance" {
    ami = "ami-0817d428a6fb68645"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "devops_training"
    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.web-server-nic.id
    }
    user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install apache2 -y
    sudo systemctl start apache2 -y
    sudo bash -c 'echo First Web Server > /var/www/html/index.html'
    EOF
    tags = {
        Name = "Web-server"
    }
}

output "server_ip_address" {
    value = aws_eip.one.public_ip
} 

output "instance_id" {
  value = aws_instance.web-server-instance.id
}

