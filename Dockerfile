FROM centos:7
ENV container docker

RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum -y install dnf
RUN dnf -y install nodejs tar sudo git-all memcached postgresql-devel postgresql-server libxml2-devel libxslt-devel patch gcc-c++ openssl-devel gnupg curl which net-tools ; dnf clean all

# Set up systemd
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]

RUN systemctl enable memcached
RUN su  - postgres -c 'initdb -E UTF8'
RUN systemctl enable postgresql

## 2. RVM
RUN /usr/bin/curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
RUN /usr/bin/curl -sSL https://get.rvm.io | rvm_tar_command=tar bash -s stable
RUN source /etc/profile.d/rvm.sh
RUN echo "gem: --no-ri --no-rdoc --no-document" > ~/.gemrc
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install ruby 2.2.3"
RUN /bin/bash -l -c "rvm use 2.2.3 --default"
RUN /bin/bash -l -c "gem install bundler rake"
RUN /bin/bash -l -c "gem install nokogiri -- --use-system-libraries"

RUN echo "======= Installing ManageIQ ======"
RUN su postgres -c "pg_ctl -D /var/lib/pgsql/data start" && sleep 5 && su postgres -c "psql -c \"CREATE ROLE root SUPERUSER LOGIN PASSWORD 'smartvm'\"" && su postgres -c "pg_ctl -D /var/lib/pgsql/data stop"
RUN mkdir /manageiq
WORKDIR /manageiq
RUN git clone https://github.com/ManageIQ/manageiq
WORKDIR manageiq
COPY docker_setup bin/docker_setup
RUN /bin/bash -l -c "./bin/docker_setup --no-db --no-tests"
COPY docker_run_miq bin/docker_run_miq
RUN echo "====== EVM has been set up ======"

EXPOSE 3000 4000

#CMD /usr/sbin/init & ; sleep 10 ; su postgres -c "psql -c \"CREATE ROLE root SUPERUSER LOGIN PASSWORD 'smartvm'\""; cd /manageiq/manageiq ; /bin/bash -l -c "./bin/docker_setup"  ;/bin/bash -l -c "bundle exec rake evm:start"


# CMD cd /manageiq/manageiq ; ./bin/docker_run_miq
CMD [ "/usr/sbin/init" ]
