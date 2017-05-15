FROM php:5.6-apache
MAINTAINER Sebastian Ponti <sebaponti@gmail.com>

# Build requirements
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      libcurl3-dev \
      libtool \
      autotools-dev \
      automake \
      pkg-config \
      libssl-dev \
      libevent-dev \
      bsdmainutils \
      libzmq3-dev \
      wget

# PHP + Apache dependencies
RUN apt-get update && apt-get install -yq --no-install-recommends \
      php5-cli \
      php5-curl \
      libapache2-mod-php5

# Boost library
RUN apt-get install -y \
      libboost-system-dev libboost-filesystem-dev libboost-chrono-dev \
      libboost-program-options-dev libboost-test-dev libboost-thread-dev

# Git cli
RUN apt-get update && apt-get install -y git-core && rm -rf /var/lib/apt/lists/*

# Firewall-jumping support (see --with-miniupnpc and--enable-upnp-default)
RUN apt-get update && apt-get install -y libminiupnpc-dev

# ZMQ dependencies (provides ZMQ API 4.x)
#RUN apt-get install libzmq3-dev

WORKDIR /app

ADD apache2.conf /etc/apache2/
ADD stakebox-ui.conf /etc/apache2/sites-available/

#ADD docker-navcoin-entrypoint /usr/local/bin/

# Enable apache rewrite module and add site
RUN a2enmod rewrite
RUN a2ensite stakebox-ui.conf
RUN a2dissite 000-default.conf

#VOLUME ["/code", "/data"]

# Port
EXPOSE 44440

# RPC Port
EXPOSE 44444

#ENTRYPOINT ["docker-navcoin-entrypoint"]
