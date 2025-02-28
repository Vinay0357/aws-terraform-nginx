#!/bin/bash
echo "$(hostname)" > /usr/share/nginx/html/server-info
nginx -g 'daemon off;'
