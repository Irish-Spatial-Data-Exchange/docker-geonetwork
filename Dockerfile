# base image
FROM ubuntu:latest
LABEL maintainer="Andrew Conway <andrew.conway@marine.ie>"

# Inspired by
# https://github.com/cloudbees/java-build-tools-dockerfile/blob/master/Dockerfile

# add custom apt-get sources
RUN DISTRIB_CODENAME=$(cat /etc/*release* | grep DISTRIB_CODENAME | cut -f2 -d'=') \
    && echo "deb http://archive.ubuntu.com/ubuntu ${DISTRIB_CODENAME} main universe\n" > /etc/apt/sources.list \
    && echo "deb http://archive.ubuntu.com/ubuntu ${DISTRIB_CODENAME}-updates main universe\n" >> /etc/apt/sources.list \
    && echo "deb http://security.ubuntu.com/ubuntu ${DISTRIB_CODENAME}-security main universe\n" >> /etc/apt/sources.list



# Workspace packages
RUN apt-get update -qqy \
    && apt-get -qqy --no-install-recommends install software-properties-common \
    && add-apt-repository -y ppa:git-core/ppa \
    openjdk-8-jdk \
    tar zip unzip \
    wget curl \
    git \
    build-essential \
    less nano \
    jq \
    python python3-pip \
    rsync \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/java.security

# known issues which could crop up

# workaround https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=775775
RUN [ -f "/etc/ssl/certs/java/cacerts" ] || /var/lib/dpkg/info/ca-certificates-java.postinst configure

# workaround "You are using pip version 8.1.1, however version 9.0.1 is available."
RUN pip3 install --upgrade pip setuptools

RUN pip3 install yq

# Maven - latest
ENV MAVEN_VERSION 3.6.3

RUN curl -fsSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
    && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
    && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven

# Ant - latest
ENV ANT_VERSION 1.10.9

RUN curl -fsSL https://www.apache.org/dist/ant/binaries/apache-ant-$ANT_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
    && mv /usr/share/apache-ant-$ANT_VERSION /usr/share/ant \
    && ln -s /usr/share/ant/bin/ant /usr/bin/ant

# ENV ANT_HOME /usr/share/ant

# # clone custom Repo (e.g. own organisation flavour)
# WORKDIR /usr/share/

# RUN git clone --recurse-submodules https://github.com/IrishMarineInstitute/data.marine.ie.git data-catalogue
# # OR workaround copy files from host - change first location as appropriate to your system
# # COPY H:\data-catalogue /data-catalogue

WORKDIR /usr/share/
# clone GeoNetwork Repo & Build
RUN git clone --recurse-submodules https://github.com/geonetwork/core-geonetwork.git geonetwork
WORKDIR /usr/share/geonetwork
RUN git checkout tags/3.10.6 -b build \
    && git status

# run a clean build
RUN mvn clean install -DskipTests

# # navigate back to geonetwork to pull in sub-modules for Plugins
# WORKDIR /usr/share/geonetwork/schemas
# RUN git submodule add https://github.com/metadata101/sensorML.git sensorML
# WORKDIR /usr/share/geonetwork/schemas
# RUN git submodule add https://github.com/metadata101/iso19139.sdn-csr.git \
#     && git submodule add https://github.com/metadata101/iso19139.sdn-cdi.git

# # navigate back to the data-catalogue repo & run the Ant build script to copy custom MI content to the GeoNetwork repo
# WORKDIR /usr/share/data-catalogue/geonetwork
# RUN ant -buildfile /usr/share/data-catalogue/geonetwork/mi_geonetwork_build.xml

# # navigate back to the geonetwork repo to re-run Maven build & create WAR
# WORKDIR /usr/share/geonetwork
# RUN mvn clean install -DskipTests