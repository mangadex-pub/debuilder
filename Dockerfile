ARG DEBIAN_CODENAME
FROM docker.io/library/debian:${DEBIAN_CODENAME}-slim

ARG DEBIAN_CODENAME
ENV DEBIAN_CODENAME="${DEBIAN_CODENAME}"
ARG IMAGE_VERSION
LABEL version="debuilder-${IMAGE_VERSION}"
LABEL maintainer="MangaDex open-source <opensource@mangadex.org>"

ENV DEBIAN_FRONTEND "noninteractive"
ENV TZ "UTC"
RUN echo 'Dpkg::Progress-Fancy "0";' > /etc/apt/apt.conf.d/99progressbar

RUN apt -qq update && \
    apt -qq -y --no-install-recommends install \
      apt-utils \
      apt-transport-https \
      ca-certificates && \
    sed -i -e 's/http\:/https\:/g' /etc/apt/sources.list && \
    apt -qq update && \
    apt -qq -y --no-install-recommends install \
      build-essential \
      bzip2 \
      ca-certificates \
      cmake \
      curl \
      debian-archive-keyring \
      git \
      gnupg2 \
      tar && \
    apt -qq -y --purge autoremove && \
    apt -qq -y clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/* /var/log/*
