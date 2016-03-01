FROM centos:7
ENV container docker

# Set locale manually on build (docker defaults to POSIX which causes initdb to set the wrong db encoding, MIQ must have UTF8)
# Once systemd is online, it will set locale based /etc/locale.conf

# Only needed if building with docker-1.8
ENV LANG en_US.UTF-8  

RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && yum -y install dnf && yum clean all
RUN dnf -y install nodejs tar sudo git-all memcached postgresql-devel postgresql-server libxml2-devel libxslt-devel patch gcc-c++ openssl-devel gnupg curl which net-tools ; dnf clean all 

# Set up systemd and apply cleanups
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]

# MEMCACHED and POSTGRESQL
RUN systemctl enable memcached postgresql
# Do not call a login "-" su, resets the ENV
RUN su postgres -c 'initdb -D /var/lib/pgsql/data'

## 2. RVM
RUN /usr/bin/curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
RUN /usr/bin/curl -sSL https://get.rvm.io | rvm_tar_command=tar bash -s stable
RUN source /etc/profile.d/rvm.sh ; echo "gem: --no-ri --no-rdoc --no-document" > ~/.gemrc
RUN /bin/bash -l -c "rvm requirements ; rvm install ruby 2.2.4 ; rvm use 2.2.4 --default ; gem install bundler rake ; gem install nokogiri -- --use-system-libraries" 

# GIT clone and prepare services
RUN mkdir /manageiq && git clone https://github.com/ManageIQ/manageiq /manageiq
#RUN mkdir /manageiq && cd /manageiq && git clone https://github.com/ManageIQ/manageiq
WORKDIR /manageiq
COPY docker_setup bin/docker_setup
RUN su postgres -c "pg_ctl -D /var/lib/pgsql/data start" && sleep 5 && su postgres -c "psql -c \"CREATE ROLE root SUPERUSER LOGIN PASSWORD 'smartvm'\"" && su postgres -c "pg_ctl -D /var/lib/pgsql/data stop"
RUN su postgres -c "pg_ctl -D /var/lib/pgsql/data start" && bash -l -c "/usr/bin/memcached -u memcached -p 11211 -m 64 -c 1024 -l 127.0.0.1 &" && /bin/bash -l -c "bin/docker_setup" && su postgres -c "pg_ctl -D /var/lib/pgsql/data stop" && killall memcached
COPY evmserver.sh bin/evmserver.sh
COPY evmserverd.service /usr/lib/systemd/system/evmserverd.service
RUN systemctl enable evmserverd

EXPOSE 3000 4000

# Bring up all services via systemd (fix me need evm systemd unit files)
CMD [ "/usr/sbin/init" ]
