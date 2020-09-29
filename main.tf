
provider "aws" {
  region = "us-east-1"
  access_key = "AKIAIR3HFR6ZM2KCV7PA"
  secret_key = "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"
}

# Basic Syntax to allocate resources.
#"name" is used for terraform reference.
#     resource "<provider>_<resource_type>" "name"{
#         config options...
#         key1 = "value1"
#         key2 = "value2"
#     }

############### creating ec2 instance code###############
#resource "aws_instance" "my-first-ec2" {
#  ami           = "ami-0817d428a6fb68645"
#  instance_type = "t2.micro"
#  tags = {
#      Name = "ubuntu"
#  }
#}

#####################creating VPC code #######################

#creation of subnet in the VPC
resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.first-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "prod-subnet"
  }
}

#creation of vpc
resource "aws_vpc" "first-vpc"{
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "production-vpc"
    }
}

#Note: Order of code doesn't matter as seen above. subnet code is written which is accessing the vpc defined below subnet code.


