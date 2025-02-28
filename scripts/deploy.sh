#!/bin/bash
ECR_URL=$(aws ecr describe-repositories --repository-names nginx-maintenance --query 'repositories[0].repositoryUri' --output text)

aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_URL
docker build -t nginx-maintenance ./app
docker tag nginx-maintenance:latest $ECR_URL:latest
docker push $ECR_URL:latest
