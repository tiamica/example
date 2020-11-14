FROM example:latest
MAINTAINER Emmanuel Ihenacho

ARG DOWNLOAD_URL=http://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/integration/11.0.0.10-ACE-LINUX64-DEVELOPER.tar.gz
ARG PRODUCT_LABEL=ace-11.0.0.10


RUN yum --disableplugin=subscription-manager -y module enable \
  php:7.2 \
  && yum --disableplugin=subscription-manager -y install \
  httpd php curl \
  && yum --disableplugin=subscription-manager clean all
 
# Install ACE $PRODUCT_LABEL and accept the license
RUN mkdir /opt/ibm && echo Downloading package ${DOWNLOAD_URL} && \
    curl ${DOWNLOAD_URL} | tar zx --directory /opt/ibm && \
    mv /opt/ibm/${PRODUCT_LABEL} /opt/ibm/ace-11 && \
    /opt/ibm/ace-11/ace make registry global accept license deferred

WORKDIR /opt/ibm

RUN microdnf update && microdnf install util-linux unzip python2 && microdnf clean all
COPY --from=builder /opt/ibm/ace-11 /opt/ibm/ace-11


# Create the ace workdir for user mqm, and chmod script files
RUN mkdir /home/aceuser \
  && chown mqm:mqm /home/aceuser \
  && usermod -a -G mqbrkrs mqm \
  && usermod -d /home/aceuser mqm \
  && su - mqm -c '. /opt/ibm/ace-11/server/bin/mqsiprofile && mqsicreateworkdir /home/aceuser/ace-server' \
  && chmod 755 /usr/local/bin/*

# Set BASH_ENV to source mqsiprofile when using docker exec bash -c
ENV BASH_ENV=/usr/local/bin/ace_env.sh

# Expose ports.  7600, 7800, 7843 for ACE; 1414 for MQ; 9157 for MQ metrics; 9483 for ACE metrics;
EXPOSE 7600 7800 7843 1414 9157 9483

USER mqm

WORKDIR /home/aceuser
RUN mkdir /home/aceuser/initial-config && chown mqm:mqm /home/aceuser/initial-config

ENV USE_QMGR=true LOG_FORMAT=basic

# Set entrypoint to run management script
ENTRYPOINT ["runaceserver"]

# Setup Environment
ENV SUMMARY="Integration Server for App Connect Enterprise" \
    DESCRIPTION="Integration Server for App Connect Enterprise" \
    PRODNAME="AppConnectEnterprise" \
    COMPNAME="IntegrationServer"

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="Integration Server for App Connect Enterprise" \
      io.openshift.tags="$PRODNAME,$COMPNAME" \
      com.redhat.component="$PRODNAME-$COMPNAME" \
      name="$PRODNAME/$COMPNAME" \
      vendor="IBM" \
      version="$PRODUCT_LABEL" \
      release="1" \
      license="IBM" \
      maintainer="Hybrid Integration Platform Cloud" \
      io.openshift.expose-services="" \
      usage=""

# Leaving PHP in here to test that something works

ADD index.php /var/www/html

RUN sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf \
  && mkdir /run/php-fpm \
  && chgrp -R 0 /var/log/httpd /var/run/httpd /run/php-fpm \
  && chmod -R g=u /var/log/httpd /var/run/httpd /run/php-fpm

EXPOSE 8080

USER 1001

CMD php-fpm & httpd -D FOREGROUND
