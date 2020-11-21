FROM ubi:latest 
MAINTAINER Emmanuel Ihenacho

ARG DOWNLOAD_URL=http://10.116.0.112:8080/ibm/11.0.0.10-ACE-LINUX64-DEVELOPER.tar.gz
ARG PRODUCT_LABEL=ace-11.0.0.10

USER root

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

# Run ace server
RUN export PATH=/opt/ibm:$PATH
RUN ace make registry global
RUN ace toolkit && ace tools

# Expose ports.  7600, 7800, 7843 for ACE; 1414 for MQ; 9157 for MQ metrics; 9483 for ACE metrics;
EXPOSE 7600 7800 7843 1414 9157 9483

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

