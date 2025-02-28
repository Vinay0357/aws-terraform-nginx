#!/bin/bash
sudo apt update -y
sudo apt install -y docker.io awscli
sudo systemctl start docker
sudo systemctl enable docker

aws ecr get-login-password --region us-west-1 | sudo docker login --username AWS --password-stdin 264852106485.dkr.ecr.us-west-1.amazonaws.com
sudo docker pull 264852106485.dkr.ecr.us-west-1.amazonaws.com/nginx-maintenance:latest
sudo docker run -d -p 80:80 nginx-maintenance
