FROM ubuntu:20.04

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

# Env for UTF-8 language encoding
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Env for deb conf
ENV DEBIAN_FRONTEND noninteractive

# General Apache ENVs
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
ENV APACHE_SSL_SSL_PROXY_ENGINE Off
ENV APACHE_SSL_PROXY_CHECK_PEER_NAME On
ENV APACHE_SERVER_SIGNATURE Off
ENV APACHE_SERVER_TOKENS Prod
ENV APACHE_HTTP_HEADER_X_POWERED_BY "Apache HTTP 2.4 for SSL/TLS Mutual Authentication (Ver. ${VERSION} - Git URL: ${VCS_URL} - Git Ref: ${VCS_REF})"

# For more info See https://httpd.apache.org/docs/2.4/mod/mod_http2.html
ENV APACHE_HTTP_PROTOCOLS http/1.1

# Specifics env Apache for application 
ENV APPLICATION_URL https://${APACHE_SERVER_NAME}:${APACHE_SSL_PORT}
ENV CLIENT_VERIFY_LANDING_PAGE /error.php

# Reverse Proxy Application
ENV APACHE_PROXY_PRESERVE_HOST On
ENV API_BASE_PATH /secure/api
ENV API_BACKEND_BASE_URL http://127.0.0.1:8000${API_BASE_PATH}

# Install services, packages and do cleanup
RUN apt update \
    && apt install -y apache2 \
    && apt install -y php7.4 php7.4-fpm \
    && apt install -y curl \
    && apt install -y python3-pip \
    && apt install -y git \
    && rm -rf /var/lib/apt/lists/*

# Copy Apache configuration file
COPY configs/httpd/000-default.conf /etc/apache2/sites-available/
COPY configs/httpd/default-ssl.conf /etc/apache2/sites-available/
COPY configs/httpd/ssl-params.conf /etc/apache2/conf-available/
COPY configs/httpd/dir.conf /etc/apache2/mods-enabled/
COPY configs/httpd/ports.conf /etc/apache2/

# Copy Server (pub and key) tls-auth.dontesta.it
# Copy CA Public Key
COPY configs/certs/blog.dontesta.it.ca.cer /etc/ssl/certs/
COPY configs/certs/tls-auth.dontesta.it.cer /etc/ssl/certs/
COPY configs/certs/tls-auth.dontesta.it.key /etc/ssl/private/

# Copy php samples script and other
COPY configs/www/*.php /var/www/html/
COPY configs/www/assets /var/www/html/assets
COPY configs/www/secure /var/www/html/secure
COPY images/favicon.ico /var/www/html/favicon.ico

# Copy scripts and entrypoint
COPY scripts/entrypoint /entrypoint

# Set execute flag for entrypoint
RUN chmod +x /entrypoint \
    && cd /var/www \
    && chown -R www-data:www-data /var/www/html

# Configure and enabled Apache features
RUN a2enmod ssl \
    && a2enmod headers \
    && a2enmod rewrite \
    && a2dismod mpm_prefork \
    && a2dismod mpm_event \
    && a2enmod mpm_worker \
    && a2enmod proxy_fcgi \
    && a2enmod http2 \
    && a2enmod proxy \
    && a2enmod proxy_http \
    && a2enmod remoteip \
    && a2ensite default-ssl \
    && a2enconf ssl-params \
    && a2enconf php7.4-fpm \
    && c_rehash /etc/ssl/certs/

## 
# Install PIP Environment and setup for httpbin Project
##
RUN pip3 install --no-cache-dir pipenv 

ADD .httpbin/Pipfile .httpbin/Pipfile.lock /httpbin/
WORKDIR /httpbin

RUN /bin/bash -c "pip3 install --no-cache-dir -r <(pipenv lock -r)"
ADD .httpbin/. /httpbin
RUN pip3 install --no-cache-dir /httpbin

# Expose Apache
EXPOSE ${APACHE_SSL_PORT}

# Define entry for setup contrab
ENTRYPOINT ["/entrypoint"]

# Launch Apache
CMD ["/usr/sbin/apache2ctl", "-DFOREGROUND"]
