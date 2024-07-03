#ALB SG
resource "aws_security_group" "master-alb-sg" {
  provider = aws.jenkins-master
  vpc_id   = aws_vpc.jenkins-master-vpc.id
  name     = "master-alb-sg"

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

  tags = merge(
    var.jenkins-master-tags,
    {
      Name = "master-alb-sg"
    }
  )

}

#Master SG
resource "aws_security_group" "master-sg" {
  provider = aws.jenkins-master
  vpc_id   = aws_vpc.jenkins-master-vpc.id
  name     = "master-sg"
  ingress {
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.master-alb-sg.id]
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.jenkins-master-tags,
    {
      Name = "master-sg"
    }
  )
}

#Jenkins worker SG
resource "aws_security_group" "worker-sg" {
  provider = aws.jenkins-worker
  vpc_id   = aws_vpc.jenkins-worker-vpc.id
  name     = "worker-sg"

#Allow every connection comming from master subnet (including SSH)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.jenkins-master-tags,
    {
      Name = "worker-sg"
    }
  )
}