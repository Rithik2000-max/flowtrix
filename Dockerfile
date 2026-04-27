# syntax=docker/dockerfile:1
FROM ubuntu:24.04

LABEL maintainer="trisentrix"
LABEL org.opencontainers.image.source="https://github.com/trisentrix-com/board"

ARG TARGETARCH
ARG VERSION=8.94
ARG DEBIAN_FRONTEND=noninteractive

ENV BUILD_DEPS="apt-utils gnupg wget bzip2 g++ curl libarchive-tools build-essential git ca-certificates python3 unzip"
ENV NODE_VERSION=v24.15.0
ENV NPM_VERSION=11.11.0
ENV PATH="/usr/local/bin:${PATH}"

# Copy branding assets
COPY ./public /public

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends ${BUILD_DEPS} && \
    rm -rf /var/lib/apt/lists/* && \
    # Create user
    useradd --user-group --system --home-dir /home/flowtrix flowtrix && \
    # Detect arch
    case "${TARGETARCH}" in \
    "amd64") NODE_ARCH="x64" WEKAN_ARCH="amd64" ;; \
    "arm64") NODE_ARCH="arm64" WEKAN_ARCH="arm64" ;; \
    "arm") NODE_ARCH="armv7l" WEKAN_ARCH="armhf" ;; \
    "ppc64le") NODE_ARCH="ppc64le" WEKAN_ARCH="ppc64le" ;; \
    "s390x") NODE_ARCH="s390x" WEKAN_ARCH="s390x" ;; \
    *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac && \
    # Install Node.js
    cd /tmp && \
    wget -q "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-${NODE_ARCH}.tar.gz" && \
    wget -q "https://nodejs.org/dist/${NODE_VERSION}/SHASUMS256.txt.asc" && \
    grep "node-${NODE_VERSION}-linux-${NODE_ARCH}.tar.gz" SHASUMS256.txt.asc | shasum -a 256 -c - && \
    tar xzf node-*.tar.gz -C /usr/local --strip-components=1 && \
    rm -f node-*.tar.gz SHASUMS256.txt.asc && \
    ln -s /usr/local/bin/node /usr/local/bin/nodejs && \
    # npm
    npm install -g npm@${NPM_VERSION} && \
    # Download WeKan
    mkdir -p /home/flowtrix/app && \
    cd /home/flowtrix/app && \
    wget -q "https://github.com/wekan/wekan/releases/download/v${VERSION}/wekan-${VERSION}-${WEKAN_ARCH}.zip" && \
    unzip -q wekan-${VERSION}-${WEKAN_ARCH}.zip && \
    rm wekan-${VERSION}-${WEKAN_ARCH}.zip && \
    # Install deps
    npm install --prefix ./bundle/programs/server && \
    mv ./bundle /build && \
    # 🔥 Branding
    cp /public/Flowtrix-logo.png /build/programs/web.browser/app/wekan-logo.png && \
    cp /public/Flowtrix-logo.png /build/programs/web.browser/app/Flowtrix-logo.png && \
    cp /public/logo-header.png /build/programs/web.browser/app/logo-header.png && \
    cp /public/favicon-32x32.png /build/programs/web.browser/app/favicon-32x32.png && \
    cp /public/favicon-16x16.png /build/programs/web.browser/app/favicon-16x16.png && \
    chmod 644 /build/programs/web.browser/app/*.png && \
    # Icons
    cp -r /public/android /build/programs/web.browser/app/ 2>/dev/null || true && \
    cp -r /public/ios /build/programs/web.browser/app/ 2>/dev/null || true && \
    cp -r /public/windows11 /build/programs/web.browser/app/ 2>/dev/null || true && \
    cp -r /public/svg-etc /build/programs/web.browser/app/ 2>/dev/null || true && \
    # Cleanup (NOW CORRECT)
    apt-get remove --purge -y ${BUILD_DEPS} && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /tmp/* /var/lib/apt/lists/* /home/flowtrix/app && \
    # Permissions
    mkdir -p /data && \
    chown -R flowtrix:flowtrix /data /build

USER flowtrix

ENV PORT=8080
WORKDIR /build
EXPOSE 8080

CMD ["bash", "-c", "ulimit -s 65500; exec node main.js"]