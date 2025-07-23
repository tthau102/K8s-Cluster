# provider "aws" {
#   region = "ap-east-1"
#   default_tags {
#     tags = {
#       "Project" = "DOWS",
#       "Owner"   = "tth"
#     }
#   }
# }

# resource "aws_resourcegroups_group" "dows" {
#   name = "dows"

#   resource_query {
#     query = <<JSON
# {
#   "ResourceTypeFilters": [
#     "AWS::AllSupported"
#   ],
#   "TagFilters": [
#     {
#       "Key": "Project",
#       "Values": ["DOWS"]
#     },
#     {
#       "Key": "Owner",
#       "Values": ["tth"]
#     }
#   ]
# }
# JSON
#   }
# }

# resource "local_sensitive_file" "key" {
#   content  = tls_private_key.this.private_key_openssh # ✅ Fix
#   filename = "./${aws_key_pair.key.key_name}"
# }

# resource "tls_private_key" "this" {
#   algorithm = "ED25519"
# }

# resource "aws_key_pair" "key" {
#   key_name   = "terraform-ssh-key" # ✅ Thêm key_name
#   public_key = tls_private_key.this.public_key_openssh
# }

# data "aws_ami" "ubuntu" {
#   most_recent = true
#   owners      = ["099720109477"] # Canonical

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

# resource "aws_instance" "test-instance" {
#   ami                         = data.aws_ami.ubuntu.id
#   instance_type               = "t3.micro"
#   key_name                    = aws_key_pair.key.key_name
#   subnet_id                   = aws_subnet.public-subnet-01.id # ✅ Thêm subnet
#   vpc_security_group_ids      = [aws_security_group.sg.id]     # ✅ Thêm security group
#   associate_public_ip_address = true
#   for_each = toset([
#     "jenkins-master",
#     "build-slave",
#     "ansible"
#   ])
#   tags = {
#     "Name" = "${each.key}"
#   }
# }

# resource "aws_security_group" "sg" {
#   vpc_id      = aws_vpc.main.id
#   description = "description"
#   name        = "name"

#   ingress {
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "des"
#     from_port   = 22
#     protocol    = "tcp"
#     to_port     = 22
#   }

#   egress {
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "des"
#     from_port   = 0
#     protocol    = "-1"
#     to_port     = 0
#   }
# }

# resource "aws_vpc" "main" {
#   cidr_block = "10.20.0.0/16"
#   tags = {
#     "name" = "test-vpc"
#   }
# }

# resource "aws_subnet" "public-subnet-01" {
#   vpc_id            = aws_vpc.main.id
#   availability_zone = "ap-east-1a"
#   cidr_block        = "10.20.1.0/24"
#   tags = {
#     "name" = "public-subnet-01"
#   }
# }

# resource "aws_subnet" "public-subnet-02" {
#   vpc_id            = aws_vpc.main.id
#   availability_zone = "ap-east-1b"
#   cidr_block        = "10.20.2.0/24"
#   tags = {
#     "name" = "public-subnet-02"
#   }
# }

# resource "aws_internet_gateway" "internet-gateway" {
#   vpc_id = aws_vpc.main.id
#   tags = {
#     "name" = "internet-gateway"
#   }
# }

# resource "aws_route_table" "public-rt" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.internet-gateway.id
#   }
# }

# resource "aws_route_table_association" "public-rt-ass-01" {
#   route_table_id = aws_route_table.public-rt.id
#   subnet_id      = aws_subnet.public-subnet-01.id
# }

# resource "aws_route_table_association" "public-rt-ass-02" {
#   route_table_id = aws_route_table.public-rt.id
#   subnet_id      = aws_subnet.public-subnet-02.id
# }
