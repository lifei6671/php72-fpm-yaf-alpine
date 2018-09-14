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
	
ENV YAF_VERSION=3.0.6

WORKDIR /usr/src/php/ext/
# Compile Phalcon
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

RUN apk add --update openssl \
	openssl-dev \
	libc-dev \
	freetype-dev \
	libjpeg-turbo-dev \
	libpng-dev \
	libmcrypt-dev \
	libpcre32 \
	bzip2 \
	libbz2 \
	libmemcached-dev \
	cyrus-sasl-dev \
	bzip2 \
	&& rm -rf /var/cache/apk/* 

COPY --from=0 /usr/local/lib/php/extensions/no-debug-non-zts-20170718/* /usr/local/lib/php/extensions/no-debug-non-zts-20170718/
COPY docker-entrypoint.sh /usr/local/bin/
ADD conf/php.ini /usr/local/etc/php/php.ini
ADD conf/www.conf /usr/local/etc/php-fpm.d/www.conf
ADD conf/yaf.ini /usr/local/etc/php/conf.d/yaf.ini
	
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
        && docker-php-ext-install gd \
		&& docker-php-ext-install mcrypt \
        && docker-php-ext-install mysqli \
        && docker-php-ext-install bz2 \
        && docker-php-ext-install zip \
        && docker-php-ext-install pdo \
        && docker-php-ext-install pdo_mysql \
        && docker-php-ext-install opcache \
		&& docker-php-ext-install mcrypt \
		&& docker-php-ext-enable memcached \
		&& docker-php-ext-enable redis \
		&& docker-php-ext-enable phalcon \
		&& docker-php-ext-enable igbinary \
		&& docker-php-ext-enable bcmath \
		&& docker-php-ext-enable mongo
	

RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 9000

CMD ["php-fpm"]