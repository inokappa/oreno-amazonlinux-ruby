FROM amazonlinux:1
ARG RUBY_DOWNLOAD_URL
ARG RUBY_VER
RUN yum -y update && \
    yum -y groupinstall "Development Tools" && \
    yum -y install openssl-devel readline-devel zlib-devel curl-devel libyaml-devel libffi-devel wget sudo aws-cli
RUN cd /tmp/ && \
    wget ${RUBY_DOWNLOAD_URL} -O ruby-${RUBY_VER}.tar.gz && \
    tar zxvf ruby-${RUBY_VER}.tar.gz && \
    cd ruby-${RUBY_VER} && \
    ./configure --disable-install-doc && make && make install
RUN rm -rf /var/cache/yum/ && yum clean all && rm -rf /tmp/ruby-${RUBY_VER}.tar.gz
