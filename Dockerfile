FROM php:7.1.2-fpm
MAINTAINER QEdu IT TEAM

# Ignore APT warnings about not having a TTY
ENV DEBIAN_FRONTEND noninteractive
 
RUN apt-get update \
  && apt-get upgrade -yq \
  && apt-get -yq install \
      build-essential \
      python \
      wget \
      bindfs \
      vim \
      git-core \
      g++ \
      autoconf \
      file \
      gcc \
      libc-dev \
      make \
      pkg-config \
      re2c \
  && apt-get clean -qq \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get install -y \
        ca-certificates \
        curl \
        libedit2 \
        libsqlite3-0 \
        libxml2 \
    --no-install-recommends && rm -r /var/lib/apt/lists/*

# ==============================================================================
# Install MongoDB and more dependencies
# ==============================================================================

RUN  apt-get update -qq \
  && apt-get install -y -qq \
      autoconf \
      imagemagick \
      libbz2-dev \
      libevent-dev \
      libglib2.0-dev \
      libjpeg-dev \
      libmagickcore-dev \
      libmagickwand-dev \
      libncurses-dev \
      libcurl4-openssl-dev \
      libffi-dev \
      libgdbm-dev \
      libpq-dev \
      libreadline-dev libreadline6-dev \
      libssl-dev \
      libtool \
      libxml2-dev \
      libxslt-dev \
      libyaml-dev \
      software-properties-common \
      zlib1g-dev \
      mongodb \
      supervisor \
  && docker-php-ext-install zip \
  && apt-get clean -qq \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN set -xe \
    && buildDeps=" \
        $PHP_EXTRA_BUILD_DEPS \
        libcurl4-openssl-dev \
        libedit-dev \
        libsqlite3-dev \
        libssl-dev \
        libxml2-dev \
        xz-utils \
    " \
    && apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/*


ENV NGINX_VERSION 1.10.3-1~jessie

RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
	&& echo "deb http://nginx.org/packages/debian/ jessie nginx" >> /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
						nginx=${NGINX_VERSION} \
						nginx-module-xslt \
						nginx-module-geoip \
						nginx-module-image-filter \
						nginx-module-perl \
						nginx-module-njs \
						gettext-base \
	&& rm -rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

RUN mkdir -p /var/log/supervisor 
RUN mkdir -p /home/www-data
RUN mkdir -p /var/www

ADD supervisord.conf /etc/supervisor/conf.d
ADD nginx.conf /etc/nginx
ADD php-fpm.conf /usr/local/etc/

RUN touch /var/run/nginx.pid && \
    chown -R www-data\:www-data /var/www && \
    chown -R www-data\:www-data /usr/local && \
    chown -R www-data\:www-data /home/www-data && \
    chown -R www-data\:www-data /etc/nginx/conf.d && \
    chown -R www-data\:www-data /etc/nginx/nginx.conf && \
    chown -R www-data\:www-data /var/log/supervisor && \
    chown -R www-data\:www-data /var/run/nginx.pid && \
    chown -R www-data\:www-data /var/cache/nginx/ && \
    chown -R www-data:www-data /var/log/nginx && \
    chmod -R 755 /var/log/nginx && \
    chmod 644 /etc/nginx/*

USER www-data

ENV HOME /home/www-data

RUN cd $HOME && mkdir -p $HOME/tmp

RUN cd $HOME &&\
    echo 'export PATH=$HOME/local/bin:$PATH' >> ~/.bashrc

RUN cd $HOME/tmp &&\
    curl -s https://getcomposer.org/installer | php &&\
    mv composer.phar /usr/local/bin/composer &&\
    rm -fr tmp

RUN pecl install mongodb

RUN echo "extension=mongodb.so" >> /usr/local/etc/php/conf.d/mongodb.ini

ENTRYPOINT /usr/bin/supervisord
