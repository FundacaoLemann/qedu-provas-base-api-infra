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

RUN useradd --home /home/qedu -m -U -s /bin/bash qedu

RUN echo 'Defaults !requiretty' >> /etc/sudoers; \
    echo 'qedu ALL= NOPASSWD: /usr/sbin/dpkg-reconfigure -f noninteractive tzdata, /usr/bin/tee /etc/timezone' >> /etc/sudoers;

RUN mkdir -p /var/www

RUN chown -R qedu\:qedu /var/www && chown -R qedu\:qedu /usr/local && chown -R qedu\:qedu /home/qedu

USER qedu

ENV HOME /home/qedu

RUN cd $HOME && mkdir -p $HOME/tmp

RUN cd /home/qedu &&\
    echo 'export PATH=$HOME/local/bin:$PATH' >> ~/.bashrc

RUN cd $HOME/tmp &&\
    curl -s https://getcomposer.org/installer | php &&\
    mv composer.phar /usr/local/bin/composer &&\
    rm -fr tmp

RUN pecl install mongodb

RUN echo "extension=mongodb.so" >> /usr/local/etc/php/conf.d/mongodb.ini