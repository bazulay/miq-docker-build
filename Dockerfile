FROM centos:7
ENV container docker

# Set ENV, LANG only needed if building with docker-1.8
ENV LANG en_US.UTF-8
ENV TERM xterm

# Fetch postgresql 9.4 COPR repo
RUN curl -sSLko /etc/yum.repos.d/rhscl-rh-postgresql94-epel-7.repo \
https://copr-fe.cloud.fedoraproject.org/coprs/rhscl/rh-postgresql94/repo/epel-7/rhscl-rh-postgresql94-epel-7.repo

## Install EPEL repo, yum necessary packages for the build without docs, clean all caches
RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    yum -y install --setopt=tsflags=nodocs \
                   bison                   \
                   bzip2                   \
                   cmake                   \
                   file                    \
                   gcc-c++                 \
                   git                     \
                   libffi-devel            \
                   libtool                 \
                   libxml2-devel           \
                   libxslt-devel           \
                   libyaml-devel           \
                   make                    \
                   memcached               \
                   net-tools               \
                   nodejs                  \
                   openssl-devel           \
                   patch                   \
                   rh-postgresql94-postgresql-server \
                   rh-postgresql94-postgresql-devel  \
                   readline-devel          \
                   sqlite-devel            \
                   which                   \
                   &&                      \
    yum clean all

# Add persistent data volume for postgres
VOLUME [ "/var/opt/rh/rh-postgresql94/lib/pgsql/data" ]

# Download chruby and chruby-install, install, setup environment, clean all
RUN curl -sL https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz | tar xz && \
    cd chruby-0.3.9 && make install && scripts/setup.sh && \
    echo "gem: --no-ri --no-rdoc --no-document" > ~/.gemrc && \
    echo "source /usr/local/share/chruby/chruby.sh" >> ~/.bashrc && \ 
    curl -sL https://github.com/postmodern/ruby-install/archive/v0.6.0.tar.gz | tar xz && \
    cd ruby-install-0.6.0 && make install && ruby-install ruby 2.2.4 -- --disable-install-doc && \
    echo "chruby ruby-2.2.4" >> ~/.bash_profile && \
    rm -rf ~/ruby* && rm -rf /usr/local/src/* && yum clean all

## Environment for scripts
RUN echo "export BASEDIR=/manageiq" > /etc/default/evm && \
    echo "export PATH=$PATH:/opt/rubies/ruby-2.2.4/bin:/opt/rh/rh-postgresql94/root/bin:/opt/rh/rh-postgresql94/root/usr/libexec" >> /etc/default/evm && \
    echo "[[ -s /etc/default/evm_postgres ]] && source /etc/default/evm_postgres" >> /etc/default/evm && \
    echo "export APPLIANCE_PG_SCL_NAME=rh-postgresql94" > /etc/default/evm_postgres && \
    echo "export APPLIANCE_PG_SERVICE=rh-postgresql94-postgresql" >> /etc/default/evm_postgres && \
    echo "export APPLIANCE_PG_DATA=/var/opt/rh/rh-postgresql94/lib/pgsql/data" >> /etc/default/evm_postgres && \
    echo "export APPLIANCE_PG_CHECKDB=/opt/rh/rh-postgresql94/root/usr/libexec/postgresql-check-db-dir" >> /etc/default/evm_postgres && \
    echo "[[ -s /opt/rh/\${APPLIANCE_PG_SCL_NAME}/enable ]] && source /opt/rh/\${APPLIANCE_PG_SCL_NAME}/enable" >> /etc/default/evm_postgres

## Create basedir, GIT clone miq (shallow)
RUN mkdir -p /manageiq && git clone --depth 1 https://github.com/ManageIQ/manageiq /manageiq

## Change WORKDIR to clone dir, copy docker_setup, start all, docker_setup, shutdown all, clean all
WORKDIR /manageiq
COPY docker_setup bin/docker_setup
RUN /bin/bash -l -c "/usr/bin/memcached -u memcached -p 11211 -m 64 -c 1024 -l 127.0.0.1 -d && \
    source /etc/default/evm && \
    bin/docker_setup --no-db --no-tests && \
    pkill memcached && \
    rm -rvf /opt/rubies/ruby-2.2.4/lib/ruby/gems/2.2.0/cache/*"

## Copy db init script, evmserver startup script and systemd evmserverd unit file
COPY docker_initdb bin/docker_initdb
COPY evmserver.sh bin/evmserver.sh
COPY evmserverd.service /usr/lib/systemd/system/evmserverd.service

## Scripts symblinks
RUN ln -s /manageiq/bin/evmserver.sh /usr/bin && \
    ln -s /manageiq/bin/docker_initdb /usr/bin

## Enable services on systemd
RUN systemctl enable evmserverd memcached

## Expose required container ports
EXPOSE 3000 4000

## Call systemd to bring up system
CMD [ "/usr/sbin/init" ]
