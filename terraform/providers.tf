provider "aws" {
  profile = var.profile
  region  = var.jenkins-master-region
  alias   = "jenkins-master"
}

provider "aws" {
  profile = var.profile
  region  = var.jenkins-worker-region
  alias   = "jenkins-worker"
}