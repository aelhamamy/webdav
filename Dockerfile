FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    apache2 \
    apache2-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod dav && \
    a2enmod dav_fs && \
    a2enmod auth_digest && \
    a2enmod auth_basic

# FIX: Create paths and grant completely open read/write/execute permissions (777)
RUN mkdir -p /var/lib/dav && \
    mkdir -p /var/lock/apache2 && \
    chmod -R 777 /var/lib/dav && \
    chmod -R 777 /var/lock/apache2 && \
    chown -R www-data:www-data /var/lib/dav && \
    chown -R www-data:www-data /var/lock/apache2

COPY webdav.conf /etc/apache2/sites-available/000-default.conf

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy the custom styling theme
COPY nord-theme.css /var/www/html/nord-theme.css

# Link the stylesheet directly into the DAV directory so Apache can serve it unauthenticated to the index page
RUN ln -s /var/www/html/nord-theme.css /var/lib/dav/nord-theme.css

RUN ln -sf /dev/stdout /var/log/apache2/access.log && \
    ln -sf /dev/stderr /var/log/apache2/error.log

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2ctl", "-D", "FOREGROUND"]
