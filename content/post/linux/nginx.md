
+++
title = "nginx配置"
description = "nginx配置"
tags = [
    "linux",
    "nginx"
]
date = "2018-07-26T19:01:00+08:00"
categories = [
    "linux",
]
+++


## nginx 正向代理配置

```ini
server {  
    resolver 114.114.114.114;       #指定DNS服务器IP地址  
    listen 80;  
    location / {  
        proxy_pass http://$http_host$request_uri;     #设定代理服务器的协议和地址  
        proxy_set_header HOST $http_host;
        proxy_buffers 256 4k;
        proxy_max_temp_file_size 0k; 
        proxy_connect_timeout 30;
        proxy_send_timeout 60;
        proxy_read_timeout 60;
        proxy_next_upstream error timeout invalid_header http_502;
    }  
}  
server {  
    resolver 114.114.114.114;       #指定DNS服务器IP地址  
    listen 443;  
    location / {  
       proxy_pass https://$host$request_uri;    #设定代理服务器的协议和地址  
       proxy_buffers 256 4k;
       proxy_max_temp_file_size 0k; 
       proxy_connect_timeout 30;
       proxy_send_timeout 60;
       proxy_read_timeout 60;
       proxy_next_upstream error timeout invalid_header http_502;
    }
}
```



