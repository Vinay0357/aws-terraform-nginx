#!/bin/bash
# Install Docker
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user

# Create Dockerfile and index.html
mkdir -p /home/ec2-user/docker
cat <<EOL > /home/ec2-user/docker/Dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EOL

cat <<EOL > /home/ec2-user/docker/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Maintenance Page</title>
</head>
<body>
    <h1>Maintenance Information</h1>
    <p>This is a maintenance page served by $(hostname)</p>
</body>
</html>
EOL

# Build and run the Docker container
cd /home/ec2-user/docker
docker build -t rec-nginx .
docker run -d -p 80:80 --name rec-nginx rec-nginx --restart always rec-nginx