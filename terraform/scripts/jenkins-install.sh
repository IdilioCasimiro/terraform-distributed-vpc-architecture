#! /bin/bash
sudo apt update -y

# #Install Apache
sudo apt -y install apache2

# Intall OpenJDK
sudo apt -y install openjdk-17-jdk

#Install Jenkins
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get -y install jenkins

#Start jenkins
sudo systemctl start jenkins.service
