# syntax=docker/dockerfile:1

FROM ubuntu:24.04

LABEL maintainer="trisentrix"
LABEL org.opencontainers.image.source="https://github.com/rith-tri/Flowtrix"

ARG TARGETARCH
ARG VERSION=8.94
ARG DEBIAN_FRONTEND=noninteractive

ENV BUILD_DEPS="apt-utils gnupg wget bzip2 g++ curl libarchive-tools build-essential git ca-certificates python3 unzip"
ENV NODE_VERSION=v20.19.1
ENV NPM_VERSION=11.11.0
ENV PATH="/usr/local/bin:${PATH}"

COPY ./public /public

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends ${BUILD_DEPS} && \
    rm -rf /var/lib/apt/lists/* && \
    \
    useradd --user-group --system --home-dir /home/flowtrix flowtrix && \
    \
    case "${TARGETARCH}" in \
      "amd64") NODE_ARCH="x64"; WEKAN_ARCH="amd64" ;; \
      "arm64") NODE_ARCH="arm64"; WEKAN_ARCH="arm64" ;; \
      "arm") NODE_ARCH="armv7l"; WEKAN_ARCH="armhf" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac && \
    \
    cd /tmp && \
    wget -q "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-${NODE_ARCH}.tar.gz" && \
    tar xzf node-*.tar.gz -C /usr/local --strip-components=1 && \
    rm -f node-*.tar.gz && \
    ln -s /usr/local/bin/node /usr/local/bin/nodejs && \
    \
    npm install -g npm@${NPM_VERSION} && \
    \
    mkdir -p /home/flowtrix/app && \
    cd /home/flowtrix/app && \
    \
    wget -q "https://github.com/wekan/wekan/releases/download/v${VERSION}/wekan-${VERSION}-${WEKAN_ARCH}.zip" && \
    unzip -q wekan-${VERSION}-${WEKAN_ARCH}.zip && \
    rm wekan-${VERSION}-${WEKAN_ARCH}.zip && \
    \
    mv bundle /build && \
    \
    npm install --prefix /build/programs/server && \
    \
    cp /public/Flowtrix-logo.png /build/programs/web.browser/app/wekan-logo.png && \
    cp /public/Flowtrix-logo.png /build/programs/web.browser/app/Flowtrix-logo.png && \
    cp /public/logo-header.png /build/programs/web.browser/app/logo-header.png && \
    cp /public/favicon-32x32.png /build/programs/web.browser/app/favicon-32x32.png && \
    cp /public/favicon-16x16.png /build/programs/web.browser/app/favicon-16x16.png && \
    \
    cp /public/Flowtrix-logo.png /build/programs/web.browser.legacy/app/wekan-logo.png && \
    cp /public/logo-header.png /build/programs/web.browser.legacy/app/logo-header.png && \
    \
    find /build/programs/web.browser -type f \( -name "*.js" -o -name "*.css" -o -name "*.html" \) \
      -exec sed -i 's/Wekan/Flowtrix/g' {} \; || true && \
    \
    find /build/programs/web.browser.legacy -type f \( -name "*.js" -o -name "*.css" -o -name "*.html" \) \
      -exec sed -i 's/Wekan/Flowtrix/g' {} \; || true && \
    \
    mkdir -p /data && \
    chown -R flowtrix:flowtrix /data /build

USER flowtrix

ENV PORT=8080

WORKDIR /build

EXPOSE 8080

CMD ["bash", "-c", "ulimit -s 65500; exec node main.js"]