FROM http-php:latest 
MAINTAINER Emmanuel Ihenacho

ARG DOWNLOAD_URL=http://http-php-default.apps-crc.testing/ibm/11.0.0.10-ACE-LINUX64-DEVELOPER.tar.gz
ARG PRODUCT_LABEL=ace-11.0.0.10

USER root

RUN yum --disableplugin=subscription-manager -y install rsync curl \
  && yum --disableplugin=subscription-manager clean all
 
# Install ACE $PRODUCT_LABEL and accept the license
RUN mkdir -p /opt/ibm && echo Downloading package ${DOWNLOAD_URL} && \
    curl http://http-php-default.apps-crc.testing/ibm/11.0.0.10-ACE-LINUX64-DEVELOPER.tar.gz --output /tmp/11.0.0.10-ACE-LINUX64-DEVELOPER.tar.gz
# RUN cd /tmp && tar xzvf /tmp/11.0.0.10-ACE-LINUX64-DEVELOPER.tar.gz && \
#    mv /tmp/${PRODUCT_LABEL} /opt/ibm/ace-11
# RUN ./opt/ibm/ace-11/ace make registry global accept license deferred

WORKDIR /opt/ibm/ace-11/bin

# Run ace server
# RUN export PATH=/opt/ibm/ace-11/server/bin:$PATH
# RUN . ./opt/ibm/ace-11/server/bin/mqsiprofile
# RUN . ./opt/ibm/ace-11/server/bin/IntegrationServer --work-dir /tmp/ibmace --default-application-name ibmace 

# Expose ports.  7600, 7800, 7843 for ACE; 1414 for MQ; 9157 for MQ metrics; 9483 for ACE metrics;
EXPOSE 7600

ENV USE_QMGR=true LOG_FORMAT=basic

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
