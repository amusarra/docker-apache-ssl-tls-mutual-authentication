FROM ubuntu:18.04

# Metadata params
ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL
ARG VERSION

LABEL maintainer="Antonio Musarra <antonio.musarra@gmail.com>" \
    org.label-schema.name="apache-tls-client-authentication" \
    org.label-schema.description="Apache HTTP 2.4 for SSL/TLS Mutual Authentication" \
    org.label-schema.version=${VERSION} \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.vendor="Antonio Musarra's Blog" \
    org.label-schema.url="https://www.dontesta.it" \
    org.label-schema.vcs-url=${VCS_URL} \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.schema-version="1.0"


# Env for deb conf
ENV DEBIAN_FRONTEND noninteractive

# Apache ENVs
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_SERVER_NAME tls-auth.dontesta.it
ENV APACHE_SERVER_ADMIN tls-auth@dontesta.it
ENV APACHE_SSL_CERTS tls-auth.dontesta.it.cer 
ENV APACHE_SSL_PRIVATE tls-auth.dontesta.it.key
ENV APACHE_SSL_PORT 10443
ENV APACHE_LOG_LEVEL info
ENV APACHE_SSL_LOG_LEVEL info
ENV APACHE_SSL_VERIFY_CLIENT optional
ENV APPLICATION_URL https://${APACHE_SERVER_NAME}:${APACHE_SSL_PORT}
ENV CLIENT_VERIFY_LANDING_PAGE /error.php

# Install services, packages and do cleanup
RUN apt update \
    && apt install -y apache2 \
    && apt install -y php libapache2-mod-php \
    && apt install -y curl \
    && apt install -y python \
    && rm -rf /var/lib/apt/lists/*

# Copy Apache configuration file
COPY configs/httpd/000-default.conf /etc/apache2/sites-available/
COPY configs/httpd/default-ssl.conf /etc/apache2/sites-available/
COPY configs/httpd/ssl-params.conf /etc/apache2/conf-available/
COPY configs/httpd/dir.conf /etc/apache2/mods-enabled/
COPY configs/httpd/ports.conf /etc/apache2/

# Copy Server (pub and key) cns.dontesta.it
COPY configs/certs/*.cer /etc/ssl/certs/
COPY configs/certs/*.key /etc/ssl/private/

# Copy php samples script and other
COPY configs/www/*.php /var/www/html/
COPY configs/www/assets /var/www/html/assets
COPY configs/www/secure /var/www/html/secure
COPY images/favicon.ico /var/www/html/favicon.ico

# Copy scripts and entrypoint
COPY scripts/entrypoint /entrypoint

# Set execute flag for entrypoint and crontab entry
RUN chmod +x /entrypoint \
    && cd /var/www \
    && chown -R www-data:www-data /var/www/html

# Configure and enabled Apache features
RUN a2enmod ssl \
    && a2enmod headers \
    && a2enmod rewrite \
    && a2ensite default-ssl \
    && a2enconf ssl-params \
    && c_rehash /etc/ssl/certs/

# Expose Apache
EXPOSE ${APACHE_SSL_PORT}

# Define entry for setup contrab
ENTRYPOINT ["/entrypoint"]

# Launch Apache
CMD ["/usr/sbin/apache2ctl", "-DFOREGROUND"]
