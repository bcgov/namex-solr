FROM solr:6.6
MAINTAINER  Varek Boettcher "varek.boettcher@gov.bc.ca"

USER root
ENV STI_SCRIPTS_PATH=/usr/libexec/s2i
ENV SOLR_USER="solr"
ENV POSTGRES_URL="http://central.maven.org/maven2/org/postgresql/postgresql/42.2.1/postgresql-42.2.1.jar"
ENV SOLR_JDBC_URL="http://central.maven.org/maven2/com/s24/search/solr/solr-jdbc/2.3.8/solr-jdbc-2.3.8.jar"
ENV JETTY_URL="https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/9.3.14.v20161028/jetty-distribution-9.3.14.v20161028.tar.gz"
ENV DB_UTILS_URL="http://central.maven.org/maven2/commons-dbutils/commons-dbutils/1.7/commons-dbutils-1.7.jar"

LABEL io.k8s.description="Run SOLR search in OpenShift" \
      io.k8s.display-name="SOLR 6.6" \
      io.openshift.expose-services="8983:http" \
      io.openshift.tags="builder,solr,solr6.6" \
      io.openshift.s2i.scripts-url="image:///${STI_SCRIPTS_PATH}"

COPY ./s2i/bin/. ${STI_SCRIPTS_PATH}
RUN chmod -R a+rx ${STI_SCRIPTS_PATH}

# If we need to add files as part of every SOLR conf, they'd go here
# COPY ./solr-config/ /tmp/solr-config

# Install jq, a command-line JSON parser
# To be used with the automated core loading scripts
RUN apt-get update \
    && apt-get -y install jq \
    && rm -rf /var/lib/apt/lists/*

# Overwriting (and re-chown'ing) docker-solr script pre-loads so we can add our modified ones to support bringing up
# SOLR with multiple cores
COPY scripts /opt/docker-solr/scripts
RUN chown -R $SOLR_USER /opt/docker-solr/scripts

# Copy Postgres drivers into the image
RUN wget -nv $POSTGRES_URL -O /opt/solr/server/lib/pgsql-jdbc.jar \
  && chown $SOLR_USER /opt/solr/server/lib/pgsql-jdbc.jar

# Copy Solr-JDBC library into the image
RUN wget -nv $SOLR_JDBC_URL -O /opt/solr/server/lib/solr-jdbc.jar \
  && chown $SOLR_USER /opt/solr/server/lib/solr-jdbc.jar

# Copy DB Utils library into the image
RUN wget -nv $DB_UTILS_URL -O /opt/solr/server/lib/dbutils.jar \
  && chown $SOLR_USER /opt/solr/server/lib/dbutils.jar

# Pull down Jetty; untar it; copy a bunch of files; cleanup; create Jetty Plus config file.
RUN wget -nv $JETTY_URL -O /tmp/jetty.tgz \
  && tar --directory /tmp --extract --file jetty.tgz \
  && mv /tmp/jetty-* /tmp/jetty \
  && cp /tmp/jetty/etc/jetty-plus.xml /opt/solr/server/etc \
  && cp /tmp/jetty/lib/jetty-jndi-*.jar /opt/solr/server/lib \
  && cp /tmp/jetty/lib/jetty-plus-*.jar /opt/solr/server/lib \
  && cp /tmp/jetty/modules/jndi.mod /opt/solr/server/modules \
  && cp /tmp/jetty/modules/plus.mod /opt/solr/server/modules \
  && cp /tmp/jetty/modules/security.mod /opt/solr/server/modules \
  && cp /tmp/jetty/modules/servlet.mod /opt/solr/server/modules \
  && cp /tmp/jetty/modules/webapp.mod /opt/solr/server/modules \
  && rm -f /tmp/jetty* \
  && mkdir /opt/solr/server/start.d \
  && echo "--module=plus" > /opt/solr/server/start.d/plus.ini

# Give the SOLR directory to root group (not root user)
# https://docs.openshift.org/latest/creating_images/guidelines.html#openshift-origin-specific-guidelines
RUN chgrp -R 0 /opt/solr \
  && chmod -R g+rwX /opt/solr

RUN chgrp -R 0 /opt/docker-solr \
  && chmod -R g+rwX /opt/docker-solr

USER 8983
