ARG DEBIAN_CODENAME
FROM docker.io/library/debian:${DEBIAN_CODENAME}-slim

ARG DEBIAN_CODENAME
ENV DEBIAN_CODENAME="${DEBIAN_CODENAME}"

ARG CLANG_VERSION
ENV CLANG_VERSION="${CLANG_VERSION}"

LABEL Name="DeBuilder"
ARG IMAGE_VERSION
LABEL Version="${IMAGE_VERSION}"
LABEL Vendor="MangaDex"
LABEL Maintainer="MangaDex open-source <opensource@mangadex.org>"

ENV DEBIAN_FRONTEND "noninteractive"
ENV TZ "UTC"
RUN echo 'Dpkg::Progress-Fancy "0";' > /etc/apt/apt.conf.d/99progressbar

# Setup base HTTPS+GPG APT
RUN apt -qq update && \
    apt -qq -y full-upgrade && \
    apt -qq -y --no-install-recommends install \
      apt-utils \
      apt-transport-https \
      ca-certificates \
      curl \
      debian-archive-keyring \
      gnupg2 && \
    apt -qq update && \
    apt -qq -y full-upgrade && \
    apt -qq -y --purge autoremove && \
    apt -qq -y clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/* /var/log/*

# Setup base build tools
RUN apt -qq update && \
    apt -qq -y full-upgrade && \
    apt -qq -y --no-install-recommends install \
      build-essential \
      bzip2 \
      ca-certificates \
      cmake \
      debhelper \
      devscripts \
      gdb \
      git \
      libjemalloc-dev \
      libpcre2-dev \
      libreadline-dev \
      libsystemd-dev \
      pkg-config \
      tar \
      vim \
      wget \
      zip unzip && \
    apt -qq -y --purge autoremove && \
    apt -qq -y clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/* /var/log/*

# Setup more up to date build with Clang $CLANG_VERSION & friends from the LLVM snapshots repository (bless them)
RUN curl -Ss https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor | tee /usr/share/keyrings/llvm-snapshots-archive-keyring.gpg >/dev/null && \
    gpg --dry-run --quiet --import --import-options import-show /usr/share/keyrings/llvm-snapshots-archive-keyring.gpg | grep "6084F3CF814B57C1CF12EFD515CF4D18AF4F7421" && \
    echo "deb [signed-by=/usr/share/keyrings/llvm-snapshots-archive-keyring.gpg] https://apt.llvm.org/${DEBIAN_CODENAME}/ llvm-toolchain-${DEBIAN_CODENAME}-${CLANG_VERSION} main" | tee /etc/apt/sources.list.d/llvm.list && \
    apt -qq update && \
    apt -qq -y full-upgrade && \
    apt -qq -y --no-install-recommends install \
      clang-${CLANG_VERSION} \
      libclang-rt-${CLANG_VERSION}-dev \
      lldb-${CLANG_VERSION} \
      lld-${CLANG_VERSION} \
      llvm-${CLANG_VERSION} \
      && \
    apt -qq -y --purge autoremove && \
    apt -qq -y clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/* /var/log/*

RUN update-alternatives --install /usr/bin/cc  cc  /usr/bin/clang-${CLANG_VERSION}   100 && \
    update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-${CLANG_VERSION} 100 && \
    cc --version && \
    c++ --version

# Setup common library dependencies (ie most things will end up depending on it)
RUN apt -qq update && \
    apt -qq -y full-upgrade && \
    apt -qq -y --no-install-recommends install \
      libpcre2-dev \
      libreadline-dev \
      libsystemd-dev \
      zlib1g-dev && \
    apt -qq -y --purge autoremove && \
    apt -qq -y clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/* /var/log/*
