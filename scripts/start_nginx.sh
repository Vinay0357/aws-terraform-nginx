#!/bin/bash
docker build -t custom-nginx .
docker run -d --name nginx -p 80:80 custom-nginx