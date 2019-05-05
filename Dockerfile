FROM php:5.6-apache

ARG USER_ID
ARG GROUP_ID

# Add user with specified (or default) user/group ids
ENV USER_ID=${USER_ID:-1000}
ENV GROUP_ID=${GROUP_ID:-1000}

# Add our user and group first to make sure their IDs get assigned consistently,
# regardless of whatever dependencies get added
RUN groupadd -g ${GROUP_ID} navcoin \
      && useradd -u ${USER_ID} -g navcoin -s /bin/bash -m -d /navcoin navcoin

# Enviroments for building
ENV GIT_REVISION_CORE=${GIT_REVISION_CORE:-'v4.0.6'}

# Installing packages
RUN apt-get update && apt-get install -yq --no-install-recommends \	
		gosu wget git nano qrencode  \
      && apt-get clean  \
      && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

RUN cd /tmp && \
    wget https://github.com/NAVCoin/navcoin-core/releases/download/4.5.2/navcoin-4.5.2-arm-linux-gnueabihf.tar.gz && \
    tar xvzf navcoin-4.5.2-arm-linux-gnueabihf.tar.gz -C /navcoin && \
    rm -rf /tmp/*
	
# Install Stakebox UI
RUN export UI_FOLDER="/home/stakebox/" && mkdir -p $UI_FOLDER && cd $UI_FOLDER \
     && git clone https://github.com/NAVCoin/navpi.git UI \
     && cd UI && rm -fr .git .htaccess .htaccess.swp \
     && chown navcoin:navcoin $UI_FOLDER \
     && chown -R www-data:www-data $UI_FOLDER/UI


# Copy files
ADD ./conf/apache2.conf /etc/apache2/
ADD ./conf/navpi.conf /etc/apache2/sites-available/
ADD ./bin /usr/local/bin
ADD docker-entrypoint.sh /usr/local/bin/docker-entrypoint

# Create ssl certificate
RUN mkdir /etc/apache2/ssl && cd /etc/apache2/ssl \
	 && PASSWORD=$(openssl rand -hex 16) \
      && openssl genrsa -des3 -passout "pass:${PASSWORD}" -out tmp-navpi-ssl.key 2048 \
      && openssl rsa -passin "pass:${PASSWORD}" -in tmp-navpi-ssl.key -out navpi-ssl.key \
      && openssl req -new -key navpi-ssl.key -out navpi-ssl.csr \
         -subj "/C=IL/O=Nav Coin/OU=Nav Pi/CN=my.navpi.org" \
      && openssl x509 -req -days 365 -in navpi-ssl.csr -signkey navpi-ssl.key -out navpi-ssl.crt \
      && rm tmp-navpi-ssl.key navpi-ssl.csr \
      # Enable apache modules and site
      && a2enmod rewrite && a2enmod php5 && a2enmod ssl \
      && a2ensite navpi.conf && a2dissite 000-default.conf

RUN ln -s /navcoin/navcoin-*/bin/navcoind /usr/local/bin/navcoind

VOLUME ["/navcoin"]

EXPOSE 44440 44444

ENTRYPOINT ["docker-entrypoint"]

CMD ["apache2-foreground"]
