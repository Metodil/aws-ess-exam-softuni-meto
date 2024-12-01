# vpc resource
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}
# Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "main-igw"
  }
}
# public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

#route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
# Create and store SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#resource "local_file" "private_key" {
#  content  = tls_private_key.ssh_key.private_key_pem
#  filename = "./.ssh/terraform_rsa"
#  provisioner "local-exec" {
#    command = "echo '${tls_private_key.ssh_key.private_key_pem}' > ./ubuntu_ssh_key.pem"
#  }
#}

resource "local_file" "public_key" {
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = "./.ssh/terraform_rsa.pub"
}

#AWS key pair using our SSH public key
resource "aws_key_pair" "deployer" {
  key_name   = "ubuntu_ssh_key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

#security group
resource "aws_security_group" "allow_ssh_http_https" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

#EC2 Instance(Ubuntu) and Install Nginx

resource "aws_instance" "ubuntu_instance" {
  ami                         = "ami-0084a47cc718c111a"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http_https.id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  depends_on = [
    aws_security_group.allow_ssh_http_https,
    aws_internet_gateway.igw
  ]

  user_data       = file("${path.cwd}/init_ec2_web_nginx.sh")

  tags = {
    Name = "ubuntu-instance"
  }
}

output "ubuntu_instance_public_ip" {
  value = "http://${aws_instance.ubuntu_instance.public_ip}"
}
output "ubuntu_ssh_key" {
  value = "ssh_key:${tls_private_key.ssh_key.private_key_pem}"
  sensitive = true
}
