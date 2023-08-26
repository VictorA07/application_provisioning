#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sudo yum install httpd php php-mysqlnd -y
cd /var/www/html
echo "This is a test file" > indextest.html
sudo yum install wget -y
wget https://wordpress.org/wordpress-5.1.1.tar.gz
tar -xzf wordpress-5.1.1.tar.gz
sudo cp -r wordpress/* /var/www/html/
rm -rf wordpress
rm -rf wordpress-5.1.1.tar.gz
sudo chmod -R 755 wp-content
sudo chown -R apache:apache wp-content
cd /var/www/html && mv wp-config-sample.php wp-config.php
sed -i "s@define( 'DB_NAME', 'database_name_here' )@define( 'DB_NAME', '${database_name}')@g" /var/www/html/wp-config.php
sed -i "s@define( 'DB_USER', 'username_here' )@define( 'DB_USER', '${database_username}')@g" /var/www/html/wp-config.php
sed -i "s@define( 'DB_PASSWORD', 'password_here' )@define( 'DB_PASSWORD', '${database_password}')@g" /var/www/html/wp-config.php
sed -i "s@define( 'WP_DEBUG', false )@define( 'WP_DEBUG', true )@g" /var/www/html/wp-config.php
sed -i "s@define( 'DB_HOST', 'localhost' )@define( 'DB_HOST', '${element(split(":", db_endpoint), 0)}' )@g" /var/www/html/wp-config.php
chkconfig httpd on
service httpd start
sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config
sudo chmod 777 -R /var/www/html/
curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'
sudo yum install unzip -y
unzip awscliv2.zip
sudo ./aws/install
cat << EOT > /var/www/html/.htaccess
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %${REQUEST_FILENAME} !-f
RewriteCond %${REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
Rewriterule ^wp-content/uploads/(.*)$ http://${cloud_front_name}/\$1 [r=301,nc]
</IfModule>

# END WordPress
EOT
aws s3 cp --recursive /var/www/html/ s3://set16-sb-code
sudo sed -i  -e '154aAllowOverride All' -e '154d' /etc/httpd/conf/httpd.conf
echo "* * * * * ec2-user /usr/local/bin/aws s3 sync s3://set16-sb-code /var/www/html/" >> /etc/crontab
echo "* * * * * ec2-user /usr/local/bin/aws s3 sync /var/www/html/wp-content/uploads/ s3://acpet1-sb-media" >> /etc/crontab
sudo service httpd restart
sudo reboot