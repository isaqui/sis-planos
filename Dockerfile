FROM php:5.6-apache

# Configurar repositorios archivados de Debian
RUN sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org|archive.debian.org|g' /etc/apt/sources.list && \
    sed -i '/stretch-updates/d' /etc/apt/sources.list && \
    echo "Acquire::Check-Valid-Until false;" > /etc/apt/apt.conf.d/10no-check-valid-until

RUN apt-get update

RUN apt-get install -y --allow-unauthenticated \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libcurl4-openssl-dev \
    default-libmysqlclient-dev \
    wget \
    autoconf \
    g++ \
    make \
    re2c \
    iputils-ping \
    telnet \
	locales \
    libmcrypt-dev \
    && rm -rf /var/lib/apt/lists/*
	
# Configurar el locale español (necesario para setlocale)
RUN echo "es_ES.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen es_ES.UTF-8

# Establecer variables de entorno para el locale (opcional, pero recomendado)
ENV LC_TIME es_ES.UTF-8
ENV LANG es_ES.UTF-8

# Compilar extensión mysql
RUN cd /tmp && \
    wget -q https://www.php.net/distributions/php-5.6.40.tar.gz && \
    tar -xzf php-5.6.40.tar.gz && \
    cd php-5.6.40/ext/mysql && \
    phpize && \
    ./configure --with-mysql=mysqlnd && \
    make -j$(nproc) && \
    make install && \
    echo "extension=mysql.so" > /usr/local/etc/php/conf.d/docker-php-ext-mysql.ini && \
    cd /tmp && \
    rm -rf php-5.6.40*

# Configurar extensión GD
RUN docker-php-ext-configure gd \
    --with-jpeg-dir=/usr \
    --with-png-dir=/usr \
    --with-freetype-dir=/usr

# Instalar extensiones PHP
RUN docker-php-ext-install -j$(nproc) \
    gd \
    mysql \
    mysqli \
    pdo \
    pdo_mysql \
    mbstring \
    bcmath \
    curl \
    zip \
    fileinfo \
    iconv \
    exif \
    opcache \
    mcrypt
    
    #xmlrpc \

# Configurar Apache
RUN echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf && \
    a2enconf servername && \
    a2enmod rewrite && \
    sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# Configuración de permisos para Apache
RUN echo '<Directory /var/www/html/>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' > /etc/apache2/conf-available/docker-vhost.conf && \
    a2enconf docker-vhost

# Ajustar usuario de sistema
RUN usermod -u 1000 www-data && \
    groupmod -g 1000 www-data

# COPIAR archivos de la ap en contenedor
COPY php.ini /usr/local/etc/php/php.ini
COPY mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf

# Establecer permisos por defecto al directorio de proyecto
RUN chown -R www-data:www-data /var/www/html && \
    find /var/www/html -type d -exec chmod 755 {} \; && \
    find /var/www/html -type f -exec chmod 644 {} \;

# Ejecutar sh para proyecto
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]

EXPOSE 80