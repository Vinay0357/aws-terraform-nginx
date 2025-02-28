#!/bin/bash
echo "<h1>Maintenance Page</h1><p>Server: $(hostname -I)</p>" > /usr/share/nginx/html/server-info
nginx -g "daemon off;"
