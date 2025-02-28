#!/bin/bash
docker build -t custom-nginx .
docker run -d --name nginx -p 81:81 custom-nginx
