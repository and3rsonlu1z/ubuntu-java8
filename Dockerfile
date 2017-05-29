FROM ubuntu:16.04
MAINTAINER anderson@infraops.info

# envs for maintaining java updates
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get install -y --no-install-recommends curl ca-certificates software-properties-common wget

RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer

RUN ln -sf /usr/lib/jvm/java-8-oracle/bin/java /usr/bin/

RUN cd /tmp/ \
  && curl -sLO $(curl -s https://api.github.com/repos/yelp/dumb-init/releases/latest \
    | awk '/browser_download_url/ { print $2 }' \
    | sed 's/"//g'|grep -m 1 -E '\.deb$') \
  && curl -sLO $(curl -s https://api.github.com/repos/yelp/dumb-init/releases/latest \
    | awk '/browser_download_url/ { print $2 }' \
    | sed 's/"//g'|grep sha256sums) \
  && sha256sum -c ./sha256sums --ignore-missing --quiet \
  && dpkg -i ./*dumb-init*.deb \
  && rm -f ./sha256sums ./*dumb-init*

RUN cd /usr/local/bin \
  && curl -sLO $(curl -s https://api.github.com/repos/tianon/gosu/releases/latest \
    | awk '/browser_download_url/ { print $2 }' \
    | sed 's/"//g'|grep -E "gosu-$(dpkg --print-architecture)\$") \
  && curl -sLO $(curl -s https://api.github.com/repos/tianon/gosu/releases/latest \
    | awk '/browser_download_url/ { print $2 }' \
    | sed 's/"//g'|grep -E 'SHA256SUMS$') \
  && sha256sum -c ./SHA256SUMS --ignore-missing --quiet \
  && mv gosu-$(dpkg --print-architecture) gosu \
  && chmod +x gosu \
  && rm -f SHA256SUMS
RUN cd /usr/local/bin \
  && curl -sL $(curl -s https://api.github.com/repos/jwilder/dockerize/releases/latest \
    | grep -E 'browser_.*amd64' | cut -d\" -f4) | tar xzv \
  && chmod +x dockerize

RUN DEBIAN_FRONTEND=noninteractive apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /var/log/*

ENTRYPOINT ["/usr/bin/dumb-init"]
