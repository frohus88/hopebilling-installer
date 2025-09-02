#!/bin/bash
# HopeBilling 一键安装脚本 for Ubuntu
# Author: ChatGPT

set -e

echo "=== 更新系统包 ==="
apt update -y && apt upgrade -y

echo "=== 安装基础环境 ==="
apt install -y nginx mariadb-server php php-fpm php-mysql php-xml php-mbstring php-curl php-zip unzip git wget curl

echo "=== 启动并设置开机自启 ==="
systemctl enable --now nginx mariadb

echo "=== 配置数据库 ==="
DB_NAME=hopebilling
DB_USER=hb_user
DB_PASS=$(openssl rand -hex 8)

mysql -uroot <<EOF
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "数据库信息："
echo "DB_NAME=$DB_NAME"
echo "DB_USER=$DB_USER"
echo "DB_PASS=$DB_PASS"

echo "=== 下载 HopeBilling ==="
mkdir -p /var/www/hopebilling
cd /var/www/hopebilling
wget -O hopebilling.zip https://github.com/hopebilling/hopebilling/releases/latest/download/hopebilling.zip
unzip hopebilling.zip
rm hopebilling.zip

echo "=== 设置权限 ==="
chown -R www-data:www-data /var/www/hopebilling

echo "=== 配置 Nginx ==="
PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
cat >/etc/nginx/sites-available/hopebilling.conf <<EOF
server {
    listen 80;
    server_name _;

    root /var/www/hopebilling;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$PHP_VER-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

ln -s /etc/nginx/sites-available/hopebilling.conf /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

echo "=== 安装完成 ==="
echo "请访问 http://服务器IP 继续 HopeBilling 安装向导"
echo "数据库信息：DB_NAME=$DB_NAME, DB_USER=$DB_USER, DB_PASS=$DB_PASS"
