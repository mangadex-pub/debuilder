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
    sed -i -e 's/http\:/https\:/g' /etc/apt/sources.list && \
    apt -qq update && \
    apt -qq -y full-upgrade

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
      git \
      pkg-config \
      tar

# Setup more up to date build with Clang 14 & friends from the LLVM snapshots repository (bless them)
RUN curl -Ss https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor | tee /usr/share/keyrings/llvm-snapshots-archive-keyring.gpg >/dev/null && \
    gpg --dry-run --quiet --import --import-options import-show /usr/share/keyrings/llvm-snapshots-archive-keyring.gpg | grep "6084F3CF814B57C1CF12EFD515CF4D18AF4F7421" && \
    echo "deb [signed-by=/usr/share/keyrings/llvm-snapshots-archive-keyring.gpg] https://apt.llvm.org/${DEBIAN_CODENAME}/ llvm-toolchain-${DEBIAN_CODENAME}-14 main" | tee /etc/apt/sources.list.d/llvm.list && \
    apt -qq update && \
    apt -qq -y full-upgrade && \
    apt -qq -y --no-install-recommends install \
      clang-14 \
      clangd-14 \
      libclang-common-14-dev \
      libclang-14-dev \
      libclang1-14

RUN update-alternatives --install /usr/bin/cc  cc  /usr/bin/clang-14   100 && \
    update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-14 100

# Clean image of temporary files
# This works in our case because we use kaniko and single-snapshot, like civilised people.
#
# On that note, take a moment to appreciate how Docker's default choice of preserving layers was always one
# of the stupidest ideas possible, and that babbling shit about CoW benefits of Docker layer reuse is stupid
# as illustrated by the fact that it is as a result best-practice to cram all the RUN steps in a single
# invocation, specifically because no one even remotely gives a rat's ass about layer reuse in the first place.
RUN apt -qq -y --purge autoremove && \
    apt -qq -y clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/* /var/log/*
