FROM php:8-apache

# Install the necessary PHP extentions and tools
RUN apt-get update && apt-get install -y \
    libzip-dev \
    zip \
    unzip \
    && docker-php-ext-install zip \
    && docker-php-ext-install mysqli \
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy apache configuration file and enable mod_rewrite
COPY apache-config.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Copy application source files and set the permissions
COPY html /var/www/
RUN chown -R www-data:www-data /var/www

# Install Composer dependencies
WORKDIR /var/www
RUN composer install

# Expose the port and start the Apache server.
EXPOSE 80
CMD ["apache2-foreground"]
