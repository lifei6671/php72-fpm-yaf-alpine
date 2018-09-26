FROM php:7.2.6-fpm-alpine

ADD conf/php.ini /usr/local/etc/php/php.ini
ADD conf/www.conf /usr/local/etc/php-fpm.d/www.conf

ENV IMAGICK_VERSION 3.4.2
#Alpine packages
RUN apk add --update git make gcc g++ imagemagick-dev \
	libc-dev \
	autoconf \
	icu-dev \
	openldap-dev \
	freetype-dev \
	libjpeg-turbo-dev \
	libpng-dev \
	libmcrypt-dev \
	libpcre32 \
	bzip2 \
	libbz2 \
	bzip2-dev \
	libmemcached-dev \
	cyrus-sasl-dev \
	binutils \
	&& rm -rf /var/cache/apk/* 

		 
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
        && docker-php-ext-install gd \
        && docker-php-ext-install mysqli \
        && docker-php-ext-install bz2 \
        && docker-php-ext-install zip \
        && docker-php-ext-install pdo \
        && docker-php-ext-install pdo_mysql \
        && docker-php-ext-install opcache \
		&& docker-php-ext-install ldap \
		&& echo "extension=memcached.so" > /usr/local/etc/php/conf.d/memcached.ini \
		&& echo "extension=redis.so" > /usr/local/etc/php/conf.d/phpredis.ini \
		&& echo "extension=phalcon.so" > /usr/local/etc/php/conf.d/phalcon.ini \
		&& echo "extension=igbinary.so" > /usr/local/etc/php/conf.d/igbinary.ini \
		&& echo "extension=bcmath.so" > /usr/local/etc/php/conf.d/bcmath.ini 

		
WORKDIR /usr/src/php/ext/

RUN git clone -b php7-dev-playground1 https://github.com/igbinary/igbinary.git && \
	cd igbinary && phpize && ./configure CFLAGS="-O2 -g" --enable-igbinary && make install
	
# Compile Memcached 
RUN git clone -b php7 https://github.com/php-memcached-dev/php-memcached.git && \
	cd php-memcached && phpize && ./configure && make && make install
	
ENV PHPREDIS_VERSION=3.0.0

RUN set -xe && \
	curl -LO https://github.com/phpredis/phpredis/archive/${PHPREDIS_VERSION}.tar.gz && \
	tar xzf ${PHPREDIS_VERSION}.tar.gz && cd phpredis-${PHPREDIS_VERSION} && phpize && ./configure --enable-redis-igbinary && make && make install 
	
# Compile Phalcon
ENV PHALCON_VERSION=3.4.1
RUN set -xe && \
    curl -LO https://github.com/phalcon/cphalcon/archive/v${PHALCON_VERSION}.tar.gz && \
    tar xzf v${PHALCON_VERSION}.tar.gz && cd cphalcon-${PHALCON_VERSION}/build && sh install
	
# Compile Mongo
ENV MONGO_VERSION=1.5.2
RUN set -xe && \
	curl -LO https://pecl.php.net/get/mongodb-${MONGO_VERSION}.tgz && \
	tar xzf mongodb-${MONGO_VERSION}.tgz && cd mongodb-${MONGO_VERSION}  && phpize && ./configure && make && make install 

WORKDIR /usr/src/php/ext/
# Compile Yaf
ENV YAF_VERSION=3.0.6
RUN set -xe && \
    curl -LO https://github.com/laruence/yaf/archive/yaf-${YAF_VERSION}.tar.gz && \
    tar xzf yaf-${YAF_VERSION}.tar.gz && cd yaf-yaf-${YAF_VERSION} && phpize && ./configure --with-php-config=/usr/local/bin/php-config && make && make install

ADD conf/yaf.ini /usr/local/etc/php/conf.d/yaf.ini

RUN docker-php-source extract \
	&& cd /usr/src/php/ext/bcmath \
	&& phpize && ./configure --with-php-config=/usr/local/bin/php-config && make && make install \
	&& make clean \
	&& docker-php-source delete

	
FROM php:7.2.6-fpm-alpine

LABEL maintainer="longfei6671@163.com"

RUN apk add --update \
	libc-dev \
	autoconf \
	icu-dev \
	openldap-dev \
	freetype-dev \
	libjpeg-turbo-dev \
	libpng-dev \
	libmcrypt-dev \
	libpcre32 \
	bzip2 \
	libbz2 \
	bzip2-dev \
	libmemcached-dev \
	cyrus-sasl-dev \
	binutils \
	&& rm -rf /var/cache/apk/* 

COPY --from=0 /usr/local/lib/php/extensions/no-debug-non-zts-20170718/* /usr/local/lib/php/extensions/no-debug-non-zts-20170718/
COPY docker-entrypoint.sh /usr/local/bin/
ADD conf/php.ini /usr/local/etc/php/php.ini
ADD conf/www.conf /usr/local/etc/php-fpm.d/www.conf
ADD conf/yaf.ini /usr/local/etc/php/conf.d/yaf.ini
	
RUN echo "extension=pdo.so" > /usr/local/etc/php/conf.d/pdo.ini \
		&& echo "extension=ldap.so" > /usr/local/etc/php/conf.d/ldap.ini \
		&& echo "extension=gd.so" > /usr/local/etc/php/conf.d/gd.ini \
		&& echo "extension=mysqli.so" > /usr/local/etc/php/conf.d/mysqli.ini \
		&& echo "extension=bz2.so" > /usr/local/etc/php/conf.d/bz2.ini \
		&& echo "extension=zip.so" > /usr/local/etc/php/conf.d/zip.ini \
		&& echo "extension=pdo_mysql.so" > /usr/local/etc/php/conf.d/pdo_mysql.ini \
		&& echo "extension=opcache.so" > /usr/local/etc/php/conf.d/opcache.ini \
		&& echo "extension=memcached.so" > /usr/local/etc/php/conf.d/memcached.ini \
		&& echo "extension=redis.so" > /usr/local/etc/php/conf.d/phpredis.ini \
		&& echo "extension=phalcon.so" > /usr/local/etc/php/conf.d/phalcon.ini \
		&& echo "extension=igbinary.so" > /usr/local/etc/php/conf.d/igbinary.ini \
		&& echo "extension=mongodb.so" > /usr/local/etc/php/conf.d/mongodb.ini \
		&& echo "extension=bcmath.so" > /usr/local/etc/php/conf.d/bcmath.ini 
	

EXPOSE 9000

CMD ["php-fpm"]