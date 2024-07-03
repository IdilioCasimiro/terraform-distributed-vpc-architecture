data "aws_s3_bucket" "main-s3bucket" {
  provider = aws.jenkins-master
  bucket   = "idiliocasimiro-terraformstatebucket"
}

#ALB configuration
resource "aws_lb" "master-alb" {
  provider           = aws.jenkins-master
  name               = "master-alb"
  internal           = false
  security_groups    = [aws_security_group.master-alb-sg.id]
  subnets            = [aws_subnet.master-subnet-1.id, aws_subnet.master-subnet-2.id]
  load_balancer_type = "application"

#  access_logs {
#   bucket  = data.aws_s3_bucket.main-s3bucket.id
#    prefix  = "alb"
#    enabled = true
#  }

  tags = merge(
    var.jenkins-master-tags,
    {
      Name = "master-alb"
    }
  )
}

#ALB target group
resource "aws_lb_target_group" "master-alb-tg" {
  provider = aws.jenkins-master
  name     = "master-alb-tg"
  port     = var.webserver-port
  protocol = "HTTP"
  vpc_id   = aws_vpc.jenkins-master-vpc.id

  health_check {
    enabled  = true
    interval = 10
    path     = "/"
    port     = var.webserver-port
    protocol = "HTTP"
    matcher  = "200-299"
  }

  tags = merge(
    var.jenkins-master-tags,
    {
      Name = "master-alb-tg"
    }
  )
}

#ALB target group attachment for registering instances on tg
resource "aws_lb_target_group_attachment" "master-alb-tg-attachment" {
    provider = aws.jenkins-master
    target_group_arn = aws_lb_target_group.master-alb-tg.arn
    target_id = aws_instance.jenkins-master.id
    port = var.webserver-port
}

resource "aws_lb_listener" "master-alb-listener" {
  provider = aws.jenkins-master
  load_balancer_arn = aws_lb.master-alb.arn
  port = var.webserver-port
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.master-alb-tg.arn
  }

  tags = merge(
    var.jenkins-master-tags,
    {
      Name = "master-alb-listener"
    }
  )
}

#Get ami ids
data "aws_ssm_parameter" "ec2-ami" {
  provider = aws.jenkins-master
  name     = "/aws/service/canonical/ubuntu/server/20.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

data "aws_ssm_parameter" "ec2-worker-ami" {
  provider = aws.jenkins-worker
  name     = "/aws/service/canonical/ubuntu/server/20.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

#Key pair for jenkins master
resource "aws_key_pair" "jenkins-master-kp" {
  provider   = aws.jenkins-master
  key_name   = "jenkins"
  public_key = file("~/.ssh/id_rsa.pub")
}

#Key pair for jenkins worker
resource "aws_key_pair" "jenkins-worker-kp" {
  provider   = aws.jenkins-worker
  key_name   = "jenkins"
  public_key = file("~/.ssh/id_rsa.pub")
}

#Jenkins master EC2
resource "aws_instance" "jenkins-master" {
  provider                    = aws.jenkins-master
  ami                         = data.aws_ssm_parameter.ec2-ami.value
  instance_type               = var.instance_type
  security_groups             = [aws_security_group.master-sg.id]
  subnet_id                   = aws_subnet.master-subnet-1.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.jenkins-master-kp.key_name
  user_data                   = fileexists("scripts/jenkins-install.sh") ? file("scripts/jenkins-install.sh") : null

  tags = merge(
    var.jenkins-master-tags,
    {
      Name = "jenkins-master"
    }
  )

  depends_on = [aws_main_route_table_association.set-master-main-rt]
}

#Jenkins worker EC2
resource "aws_instance" "jenkins-workers" {
  provider                    = aws.jenkins-worker
  count                       = var.worker-instance-number
  ami                         = data.aws_ssm_parameter.ec2-worker-ami.value
  instance_type               = var.instance_type
  security_groups             = [aws_security_group.worker-sg.id]
  subnet_id                   = aws_subnet.worker-subnet-1.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.jenkins-worker-kp.key_name

  tags = merge(
    var.jenkins-worker-tags,
    {
      Name = join("-", ["jenkins-worker", count.index + 1])
    }
  )

  depends_on = [aws_instance.jenkins-master, aws_main_route_table_association.set-master-main-rt]
}
