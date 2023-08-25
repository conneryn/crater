FROM php:8.1-fpm

# Arguments defined in docker-compose.yml
ARG user
ARG uid

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    libpng-dev \
    libpq-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    libmagickwand-dev \
    mariadb-client

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pecl install imagick \
    && docker-php-ext-enable imagick

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql pdo_pgsql mbstring zip exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user /var/www/ && \
    chmod -R 775 /var/www/

# Setup basic uploads configuration
COPY docker-compose/php/uploads.ini /usr/local/etc/php/conf.d/uploads.ini

# Set working directory
WORKDIR /var/www

# Copy the rest of the project files
COPY --chown=0:$user . .

# Setup install composer dependencies
RUN composer install -q --no-interaction --prefer-dist --optimize-autoloader

# Ensure crater can write to storage/cache folders
RUN chmod 775 storage/framework/ storage/logs/ bootstrap/cache/

# Initiate empty .env
RUN touch .env

# Setup entry point
COPY --chmod=0755 docker-compose/entrypoint.sh /usr/local/

CMD ["php-fpm"]
ENTRYPOINT ["/usr/local/entrypoint.sh"]

# Set user for all application files
USER $user