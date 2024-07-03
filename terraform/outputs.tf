output "jenkins-master-pip" {
  description = "Shows jenkins master PIP"
  value       = aws_instance.jenkins-master.public_ip
}

output "jenkins-workers-pips" {
  description = "Shows jenkins workers PIPs"
  value       = [for instance in aws_instance.jenkins-workers : instance.public_ip]
}

output "master-alb-dns" {
  value = aws_lb.master-alb.dns_name
}