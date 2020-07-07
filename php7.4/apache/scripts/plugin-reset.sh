./reset.sh
rm -rf /var/www/html/
ln -s /wordpress /var/www/html
service apache2 restart
