#Common variables
variable "profile" {
  type    = string
  default = "default"
}

variable "external_ip" {
  type    = string
  default = "0.0.0.0/0"
}

variable "instance_type" {
  description = "Instance type for all intances"
  default     = "t3.medium"
}

#Jenkins master variables

variable "jenkins-master-region" {
  type    = string
  default = "us-east-1"
}

variable "jenkins-master-tags" {
  type = map(string)
  default = {
    "Group"       = "jenkins-master"
    "Environment" = "production"
    "Region"      = "us-east-1"
  }
}

variable "webserver-port" {
  type    = number
  default = 80
}

#Jenkins worker variables

variable "jenkins-worker-region" {
  type    = string
  default = "us-west-2"
}

variable "jenkins-worker-tags" {
  type = map(string)
  default = {
    "Group"       = "jenkins-worker"
    "Environment" = "production"
    "Region"      = "us-west-2"
  }
}

variable "worker-instance-number" {
  default = 2
}