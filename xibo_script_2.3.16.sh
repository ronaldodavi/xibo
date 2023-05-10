#!/bin/bash
# Para Centos 7
# Xibo install script
# CMS 2.2.16, MariaDB 5.5 , Apache,  PHP7.4, zeromq, openXR
# Por Ronaldo davi
# 25/04/2023
# Versão 1.0.2.3

# Desativando selinux
setenforce 0
wait
sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
wait
# Atualizando SO
yum update -y
wait
# instalando apache e utils
yum install -y httpd libtool gcc-c++ glib* zip vim wget git yum-utils 
wait
yum install -y epel-release 
wait
yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm  
wait
# ativar PHP 7.4 
yum-config-manager --disable 'remi-php*'
wait
yum-config-manager --enable remi-php74
wait
# cache rapido do yum
sudo yum makecache fast -y 
wait
yum update -y  
wait
# Instalar MariaDB5.5 e php7.4
yum install -y php 
wait
yum install -y php-devel php-soap php-common php-mysql php-gd php-mbstring php-mcrypt php-xmlrpc php-zip php-intl php-mysqlnd php-dom php-simplexml php-xml php-xmlreader php-curl php-exif php-ftp php-gd php-iconv php-json php-mbstring php-posix php-sockets php-tokenizer php-cli php-smtp php-imagick php-opcache 
wait
yum install -y zeromq-devel
wait
## install zmq.so
cd ~
wait
git clone https://github.com/zeromq/php-zmq.git
wait
cd php-zmq
wait
phpize && ./configure
wait
make && make install
wait
yum install -y mariadb-server mariadb 

# Ativar MariaDB
sudo systemctl start mariadb.service
sudo systemctl enable mariadb.service
wait
# Adicionar zeromq config 
echo "; Enable ZeroMQ extension module
extension=zmq.so
" >> /etc/php.d/20-zmq.ini
wait
# Configurando PHP
upload_max_filesize=256M
post_max_size=256M
max_execution_time=300
max_input_time=300

for key in upload_max_filesize post_max_size max_execution_time max_input_time
do
 sed -i "s/^\($key\).*/\1 $(eval echo = \${$key})/" /etc/php.ini
done
wait

# Download xibo
cd /var/www/
wait
wget https://github.com/xibosignage/xibo-cms/releases/download/2.3.16/xibo-cms-2.3.16.tar.gz

# Descompactando e instalando 
tar xvf /var/www/xibo-cms-2.3.16.tar.gz
mv /var/www/xibo-cms-2.3.16 /var/www/html/xibo2.3.16

sudo chown -R apache:apache /var/www/html/
sudo chmod -R 755 /var/www/html/

systemctl enable --now httpd
systemctl start --now httpd
systemctl disable --now firewalld
systemctl stop --now firewalld

#Criacao virtualhost
echo "

 <VirtualHost *:80>
    DocumentRoot /var/www/html/xibo2.3.16/web/
    CustomLog /var/log/httpd/xibo-access.log combined
    ErrorLog /var/log/httpd/xibo-error.log
    ServerName xibo.foo.bar
    <Directory "/var/www/html/xibo2.3.16/web/">
        Options Indexes FollowSymLinks MultiViews
        Order allow,deny
        Allow from all
        Require all granted
        Allowoverride All
        RewriteEngine On
    </Directory>

 </VirtualHost>

" >> /etc/httpd/conf.d/xibo.foo.bar.conf
  
systemctl restart httpd

mysql_secure_installation
