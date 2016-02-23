FROM centos:7
ENV container docker

RUN yum -y install tar sudo git-all memcached postgresql-devel postgresql-server libxml2-devel libxslt-devel patch gcc-c++ openssl-devel gnupg curl which 

VOLUME [ "/sys/fs/cgroup" ]
RUN systemctl enable memcached    
#RUN systemctl start memcached 
RUN su  - postgres -c 'initdb' 
RUN systemctl enable postgresql 
#RUN systemctl start postgresql
#RUN su postgres -c "psql -c \"CREATE ROLE root SUPERUSER LOGIN PASSWORD 'smartvm'\""


## 2. RVM
RUN /usr/bin/curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
RUN /usr/bin/curl -sSL https://get.rvm.io | rvm_tar_command=tar bash -s stable
RUN source /etc/profile.d/rvm.sh
RUN echo "gem: --no-ri --no-rdoc --no-document" > ~/.gemrc
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install ruby 2.2"
RUN /bin/bash -l -c "rvm use 2.2 --default"
RUN /bin/bash -l -c "gem install bundler rake"
RUN /bin/bash -l -c "gem install nokogiri -- --use-system-libraries"

RUN /usr/sbin/init & 

RUN echo "======= Installing ManageIQ ======"
RUN mkdir /manageiq
WORKDIR /manageiq
RUN git clone https://github.com/ManageIQ/manageiq
WORKDIR manageiq
RUN /bin/bash -l -c "./bin/setup"
echo "====== EVM has been set up ======"

EXPOSE 3000 4000


CMD cd /manageiq/manageiq ;  /bin/bash -l -c "bundle exec rake evm:start"
