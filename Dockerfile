FROM centos:7
ENV container docker


RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum -y install dnf
RUN dnf -y install nodejs tar sudo git-all memcached postgresql-devel postgresql-server libxml2-devel libxslt-devel patch gcc-c++ openssl-devel gnupg curl which ; dnf clean all 

VOLUME [ "/sys/fs/cgroup" ]
RUN systemctl enable memcached    
RUN su  - postgres -c 'initdb' 
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

#RUN /usr/sbin/init & 

RUN echo "======= Installing ManageIQ ======"
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


CMD cd /manageiq/manageiq ; ./bin/docker_run_miq
