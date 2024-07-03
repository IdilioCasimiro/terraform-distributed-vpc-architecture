#VPCs

# Jenkins master VPC
resource "aws_vpc" "jenkins-master-vpc" {
  provider             = aws.jenkins-master
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    var.jenkins-master-tags,
    {
      Name = "jenkins-master-vpc"
    }
  )
}

# Jenkins worker vpc
resource "aws_vpc" "jenkins-worker-vpc" {
  provider             = aws.jenkins-worker
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    var.jenkins-worker-tags,
    {
      Name = "jenkins-worker-vpc"
    }
  )
}

#Internet Gateways

#Jenkins master IGW
resource "aws_internet_gateway" "jenkins-master-igw" {
  provider = aws.jenkins-master
  vpc_id   = aws_vpc.jenkins-master-vpc.id
  tags = merge(
    var.jenkins-master-tags,
    {
      Name = "jenkins-master-igw"
    }
  )
}

#Jenkins worker IGW
resource "aws_internet_gateway" "jenkins-worker-igw" {
  provider = aws.jenkins-worker
  vpc_id   = aws_vpc.jenkins-worker-vpc.id
  tags = merge(
    var.jenkins-worker-tags,
    {
      Name = "jenkins-worker-igw"
    }
  )
}

#Availability zones
data "aws_availability_zones" "available_zones" {
  state = "available"
}

#Subnets

#Jenkins master subnets
resource "aws_subnet" "master-subnet-1" {
  provider          = aws.jenkins-master
  vpc_id            = aws_vpc.jenkins-master-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available_zones.names[0]
  tags = merge(
    var.jenkins-master-tags,
    {
      Name = "master-subnet-1"
    }
  )
}

resource "aws_subnet" "master-subnet-2" {
  provider          = aws.jenkins-master
  vpc_id            = aws_vpc.jenkins-master-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = element(data.aws_availability_zones.available_zones.names, 1)
  tags = merge(
    var.jenkins-master-tags,
    {
      Name = "master-subnet-2"
    }
  )
}

#Jenkins worker subnet
resource "aws_subnet" "worker-subnet-1" {

  provider   = aws.jenkins-worker
  vpc_id     = aws_vpc.jenkins-worker-vpc.id
  cidr_block = "192.168.1.0/24"
  tags = merge(
    var.jenkins-worker-tags,
    {
      Name = "worker-subnet-1"
    }
  )
}

#VPC Peering
resource "aws_vpc_peering_connection" "master-worker-peering" {
  provider = aws.jenkins-master
  vpc_id   = aws_vpc.jenkins-master-vpc.id

  #VPC that we're going to connect ...
  peer_region = var.jenkins-worker-region
  peer_vpc_id = aws_vpc.jenkins-worker-vpc.id

  tags = {
    Name = "master-worker-peering"
  }
}

resource "aws_vpc_peering_connection_accepter" "aws_vpc_peering_connection_accepter" {
  provider                  = aws.jenkins-worker
  vpc_peering_connection_id = aws_vpc_peering_connection.master-worker-peering.id
  auto_accept               = true
}

#Routing tables

#Master VPC RT
resource "aws_route_table" "master-rt" {
  provider = aws.jenkins-master
  vpc_id   = aws_vpc.jenkins-master-vpc.id
  #For internet access
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins-master-igw.id
  }

  #For Jenkins master -> worker communication through the peering connection
  route {
    cidr_block                = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.master-worker-peering.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "master-rt"
  }
}

#Overwrite main RT with ours
resource "aws_main_route_table_association" "set-master-main-rt" {
  provider       = aws.jenkins-master
  vpc_id         = aws_vpc.jenkins-master-vpc.id
  route_table_id = aws_route_table.master-rt.id
}

#Worker VPC RT
resource "aws_route_table" "worker-rt" {
  provider = aws.jenkins-worker
  vpc_id   = aws_vpc.jenkins-worker-vpc.id
  #For internet access
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins-worker-igw.id
  }
  #For worker->master communication via VPC peering
  route {
    cidr_block                = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.master-worker-peering.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "worker-rt"
  }
}

#Overwrite main RT with ours
resource "aws_main_route_table_association" "set-worker-main-rt" {
    provider = aws.jenkins-worker
    vpc_id = aws_vpc.jenkins-worker-vpc.id
    route_table_id = aws_route_table.worker-rt.id
}