FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG KISMET_VERSION=2026-10-R1

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates wget gnupg \
    && wget -qO /tmp/kismet-release.key https://www.kismetwireless.net/repos/kismet-release.gpg.key \
    && gpg --batch --dearmor -o /usr/share/keyrings/kismet-archive-keyring.gpg /tmp/kismet-release.key \
    && rm /tmp/kismet-release.key \
    && echo 'deb [signed-by=/usr/share/keyrings/kismet-archive-keyring.gpg] https://www.kismetwireless.net/repos/apt/release/noble noble main' > /etc/apt/sources.list.d/kismet.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        "kismet=${KISMET_VERSION}" \
        "kismet-capture-linux-wifi=${KISMET_VERSION}" \
        python3 \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/kismet-entrypoint.sh
RUN chmod +x /usr/local/bin/kismet-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/kismet-entrypoint.sh"]
