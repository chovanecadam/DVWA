FROM debian:stable

# install dependencies

RUN apt-get update -y && \
    apt-get dist-upgrade -y

RUN apt-get install -y --no-install-recommends apt-utils

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    debconf-utils

RUN echo mariadb-server mysql-server/root_password password very_hard_password | debconf-set-selections && \
    echo mariadb-server mysql-server/root_password_again password very_hard_password | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apache2 \
    mariadb-server \
    php \
    php-mysql \
    php-pgsql \
    php-pear \
    php-gd \
    git

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# start services

RUN service mysql start && \ 
    mysql -uroot -pvery_hard_password -e "create database dvwa;" && \
    mysql -uroot -pvery_hard_password -e "create user dvwa@localhost identified by 'p@ssw0rd';" && \
    mysql -uroot -pvery_hard_password -e "grant all on dvwa.* to dvwa@localhost;" && \
    mysql -uroot -pvery_hard_password -e "flush privileges;"

# copy files to html directory and configure PHP

COPY . /var/www/html/
RUN mv /var/www/html/config/config.inc.php.dist /var/www/html/config/config.inc.php
RUN sed -i 's/allow_url_include = Off/allow_url_include = On/' `find /etc/php -name "php.ini" | grep apache2`
RUN chown www-data:www-data -R /var/www/html

RUN rm /var/www/html/index.html

# export port 80

EXPOSE 80

CMD service mysql start && service apache2 start && tail -f /var/log/apache2/access.log
