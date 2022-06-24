resource "aws_vpc" "mtc_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true

  tags = {
    "Name" = "dev"
  }

}

resource "aws_subnet" "mtc_public_subnet_a" {
  vpc_id                  = aws_vpc.mtc_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    "Name" = "mtc_public_subnet_a"
  }
}

resource "aws_internet_gateway" "mtc_igw" {
  vpc_id = aws_vpc.mtc_vpc.id
  tags = {
    "Name" = "mtc_igw"
  }
}

resource "aws_route_table" "mtc_public_rt" {
  vpc_id = aws_vpc.mtc_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mtc_igw.id
  }

  tags = {
    Name = "mtc_public_rt"
  }
}

resource "aws_route_table_association" "mtc_public_subnet_rt_association" {
  subnet_id      = aws_subnet.mtc_public_subnet_a.id
  route_table_id = aws_route_table.mtc_public_rt.id
}

resource "aws_security_group" "mtc_sg" {
  name        = "mtc_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.mtc_vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.mtc_vpc.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.mtc_vpc.ipv6_cidr_block]
  }

  ingress {
    description      = "SSH to VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "ssh"
    cidr_blocks      = [aws_vpc.mtc_vpc.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.mtc_vpc.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "mtc_sg"
  }
}

resource "aws_key_pair" "mtc_auth" {
  key_name   = "mtc-key"
  public_key = file(var.mtc_public_key_path)
}

resource "aws_instance" "mtc_dev" {
  ami                    = data.aws_ami.mtc_ami.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mtc_sg.id]
  key_name               = aws_key_pair.mtc_auth.key_name
  subnet_id              = aws_subnet.mtc_public_subnet_a.id
  user_data = file("userdata.tpl")
  tags = {
    Name = "mtc_dev"
  }
}