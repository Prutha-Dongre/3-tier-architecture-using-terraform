terraform {
  backend "s3" {
    bucket = "3-tier-terraformm-backend-buckett"
    key = "terraform.tf"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "three-tier-vpc" {
  region = var.region
  cidr_block = var.vpc-cidr
  tags = {
    Name = "${var.project-name}-vpc"
  }
}

resource "aws_subnet" "public-subnet" {
  vpc_id = aws_vpc.three-tier-vpc.id 
  cidr_block = var.cidr-pub-sub
  availability_zone = var.az1
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project-name}-pub-subnet"
  }
}

resource "aws_subnet" "pri-subnet-1" {
  vpc_id = aws_vpc.three-tier-vpc.id 
  cidr_block = var.cidr-pri-sub-1
  availability_zone = var.az2
  tags = {
    Name = "${var.project-name}-pri-subnet-1"
  }
}

resource "aws_subnet" "pri-subnet-2" {
  vpc_id = aws_vpc.three-tier-vpc.id 
  cidr_block = var.cidr-pri-sub-2
  availability_zone = var.az3
  tags = {
    Name = "${var.project-name}-pri-subnet-2"
  }
}

resource "aws_internet_gateway" "three-tier-Igw" {
  vpc_id = aws_vpc.three-tier-vpc.id
  tags = {
    Name = "${var.project-name}-igw"
  }
}

resource "aws_default_route_table" "three-tier-rt" {
  default_route_table_id = aws_vpc.three-tier-vpc.default_route_table_id
  tags = {
    Name = "${var.project-name}-main-rt"
  }
}

resource "aws_route" "igw_route" {
  route_table_id = aws_default_route_table.three-tier-rt.id 
  destination_cidr_block = var.igw-cidr
  gateway_id = aws_internet_gateway.three-tier-Igw.id 
}

resource "aws_nat_gateway" "three-tier-nat" {
  connectivity_type = "private"
  subnet_id         = aws_subnet.public-subnet.id
}

resource "aws_route_table" "three-tier-priv-rt" {
  vpc_id = aws_vpc.three-tier-vpc.id
  tags = {
    Name = "${var.project-name}-priv-rt"
  }
}

resource "aws_route" "nat-route" {
  route_table_id = aws_route_table.three-tier-priv-rt.id 
  destination_cidr_block = var.nat-cidr
  gateway_id = aws_nat_gateway.three-tier-nat.id 
}

resource "aws_route_table_association" "association-1" {  
    route_table_id = aws_route_table.three-tier-priv-rt.id
    subnet_id = aws_subnet.pri-subnet-1.id
}

resource "aws_route_table_association" "association-2" {  
    route_table_id = aws_route_table.three-tier-priv-rt.id
    subnet_id = aws_subnet.pri-subnet-2.id
}

resource "aws_security_group" "three-tier-sg" {
  vpc_id = aws_vpc.three-tier-vpc.id 
  name = "${var.project-name}-sg"
  description = "allow ssh, http and mysql traffic"

  ingress {
    protocol = "tcp"
    to_port = 22
    from_port = 22
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    protocol = "tcp"
    to_port = 80
    from_port = 80
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    protocol = "tcp"
    to_port = 3306
    from_port = 3306
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    protocol = -1
    to_port = 0
    from_port = 0
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  depends_on = [ aws_vpc.three-tier-vpc ]
}

resource "aws_instance" "public-server" {
  subnet_id = aws_subnet.public-subnet.id
  ami = var.ami
  instance_type = var.instance-type
  key_name = var.key
  vpc_security_group_ids = [ aws_security_group.three-tier-sg.id ]
  tags = {
    Name = "${var.project-name}proxy-server"
  }

  depends_on = [ aws_security_group.three-tier-sg]
}

resource "aws_instance" "private-server-1" {
  subnet_id = aws_subnet.pri-subnet-1.id
  ami = var.ami
  instance_type = var.instance-type
  key_name = var.key
  vpc_security_group_ids = [ aws_security_group.three-tier-sg.id ]
  tags = {
    Name = "${var.project-name}app-server"
  }

  depends_on = [ aws_security_group.three-tier-sg]
}

resource "aws_instance" "private-server-2" {
  subnet_id = aws_subnet.pri-subnet-2.id
  ami = var.ami
  instance_type = var.instance-type
  key_name = var.key
  vpc_security_group_ids = [ aws_security_group.three-tier-sg.id ]
  tags = {
    Name = "${var.project-name}db-server"
  }

  depends_on = [ aws_security_group.three-tier-sg]
}

# DB Subnet Group (required for RDS)
resource "aws_db_subnet_group" "rds_subnet_group" {
  subnet_ids = [aws_subnet.pri-subnet-1.id, aws_subnet.pri-subnet-2.id]
   tags = {
    Name = "${var.project-name}-rds-subnet-group"
  }
}

resource "aws_db_instance" "three-tier-rds" {
  identifier           = "three-tier-rds"
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"   
  db_name              = "mydb"
  username             = "admin"
  password             = "Admin12345"   

  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  publicly_accessible  = false           # stays inside private subnet
  skip_final_snapshot  = true
}