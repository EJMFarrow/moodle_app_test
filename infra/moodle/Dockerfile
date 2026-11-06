FROM php:8.3-apache-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl git unzip libicu-dev libzip-dev libxml2-dev libonig-dev libpng-dev libjpeg62-turbo-dev libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" gd intl mysqli opcache soap zip \
    && a2enmod rewrite headers \
    && sed -ri 's!/var/www/html!/var/www/moodle/public!g' /etc/apache2/sites-available/*.conf /etc/apache2/apache2.conf \
    && sed -ri 's/Listen 80/Listen 8080/; s/<VirtualHost \*:80>/<VirtualHost *:8080>/' /etc/apache2/ports.conf /etc/apache2/sites-available/000-default.conf \
    && rm -rf /var/lib/apt/lists/*

COPY moodle.ini /usr/local/etc/php/conf.d/moodle.ini

WORKDIR /var/www/moodle/public
