FROM centos:7

MAINTAINER Yee-Ting Li <ytl@slac.stanford.edu>

ENV buildDeps git make gcc-c++ readline-devel ncurses-devel libcurl-devel httpd-devel openssl-devel krb5-devel

RUN yum -y --setopt=tsflags=nodocs install wget \
      && cd /etc/yum.repos.d \
      && wget https://repo.codeit.guru/codeit.el`rpm -q --qf "%{VERSION}" $(rpm -q --whatprovides redhat-release)`.repo \
      && yum -y remove wget

RUN yum -y --setopt=tsflags=nodocs install epel-release \
      && yum -y --setopt=tsflags=nodocs update \
      && yum -y --setopt=tsflags=nodocs install httpd openssl \
      && yum -y --setopt=tsflags=nodocs install libtool httpd-tools mod_ssl perl-autodie perl-Readonly $buildDeps \
      && yum clean all

COPY conf/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf
COPY conf/httpd/conf/magic /etc/httpd/conf/magic

# install webauth from git
RUN set -ex \
    && git clone git://git.eyrie.org/kerberos/webauth.git \
    && cd webauth \
    && ./autogen\
    && ./configure \
    && make \
    && make install \
    && rm -rf webauth

# RUN yum -y remove $buildDeps

# prep directories
RUN mkdir /var/lib/webauth \
    && chown apache:apache /var/lib/webauth 

# copy httpd configs
COPY conf/httpd/conf.d/webauth.conf /etc/httpd/conf.d/webauth.conf
COPY conf/httpd/conf.d/webauth-load.conf /etc/httpd/conf.d/webauth-load.conf
COPY conf/krb5.conf /etc/krb5.conf

# copy empty cert files: use docker bind mounts to overwrite
COPY conf/httpd/certs /etc/httpd/certs

# copy app config
COPY conf/httpd/conf.d/explgbk.conf /etc/httpd/conf.d/explgbk.conf

# index redirect
COPY index.html /var/www/html/index.html

ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod -v +x /docker-entrypoint.sh

CMD ["/docker-entrypoint.sh"]

