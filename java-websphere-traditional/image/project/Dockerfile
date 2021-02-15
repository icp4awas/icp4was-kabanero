FROM {{.stack.baseimage}} as compile

USER root

RUN dnf --disableplugin=subscription-manager install -y {{.stack.epelrpm}} \
  && dnf --disableplugin=subscription-manager install -y unzip curl ca-certificates wget xmlstarlet \
  && dnf --disableplugin=subscription-manager update -y; dnf --disableplugin=subscription-manager clean all

RUN useradd --uid 1000 --gid 0 --shell /bin/bash --create-home java_user \
  && mkdir -p /mvn/repository \
  && mkdir -p /work/home \
  && mkdir -p /project \
  && mkdir -p /usr/share/maven \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn \
  && chown -R java_user:0 /mvn /work/home /project /opt/java/openjdk /usr/share/maven

USER java_user

#
# Install maven
#
# This section based upon:
#   https://github.com/kabanero-io/collections/blob/master/docker/Dockerfile-maven
#

ARG MAVEN_VERSION={{.stack.mavenversion}}
ARG USER_HOME_DIR="/root"
ARG SHA={{.stack.mavensha}}
ARG BASE_URL={{.stack.mavendownload}}/${MAVEN_VERSION}/binaries/

RUN mkdir -p /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

# Step 1: Build the user's application

#setup project folder for java build step
COPY --chown=java_user:0 . /project
COPY --chown=java_user:0 ./mvn-stack-settings.xml /usr/share/maven/conf/settings.xml

WORKDIR /project/user-app

RUN /project/util/check_version build \
 && /project/java-twas-build.sh package

####

# Step 2: Package tWAS image
FROM {{.stack.finalimage}}

WORKDIR /

COPY --from=compile /project/user-app/config/ /work/config/

COPY --from=compile /project/user-app/app/target/app.ear /work/config/user-app/
# COPY --from=compile /project/user-app/app.ear /work/config/user-app/

RUN /work/configure.sh
