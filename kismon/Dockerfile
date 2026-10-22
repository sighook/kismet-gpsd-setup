FROM debian:bookworm-slim

ARG KISMON_UID=1000
ARG KISMON_GID=1000
ARG KISMON_REF=fdc8a21551b7274f4aae96d505a0e92ce9d76785
ARG KISMET_REST_REF=0bb017f98127e5c6c13490358174316948bb1886

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        python3 \
        python3-venv \
        python3-gi \
        python3-gi-cairo \
        python3-cairo \
        python3-simplejson \
        python3-requests \
        gir1.2-gtk-3.0 \
        gir1.2-gdkpixbuf-2.0 \
        gir1.2-osmgpsmap-1.0 \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv --system-site-packages /opt/kismon \
    && /opt/kismon/bin/pip install --no-cache-dir --upgrade pip setuptools wheel

RUN git clone https://github.com/kismetwireless/python-kismet-rest.git /tmp/python-kismet-rest \
    && git -C /tmp/python-kismet-rest checkout "$KISMET_REST_REF" \
    && /opt/kismon/bin/pip install --no-cache-dir --no-deps /tmp/python-kismet-rest \
    && git clone https://github.com/Kismon/kismon.git /tmp/kismon \
    && git -C /tmp/kismon checkout "$KISMON_REF" \
    && /opt/kismon/bin/pip install --no-cache-dir /tmp/kismon \
    && rm -rf /tmp/python-kismet-rest /tmp/kismon

RUN groupadd --gid "$KISMON_GID" kismon \
    && useradd --uid "$KISMON_UID" --gid "$KISMON_GID" \
        --create-home --shell /usr/sbin/nologin kismon \
    && install -d -o "$KISMON_UID" -g "$KISMON_GID" /home/kismon/.kismon

COPY entrypoint.sh /usr/local/bin/kismon-entrypoint.sh
RUN chmod +x /usr/local/bin/kismon-entrypoint.sh

ENV HOME=/home/kismon
USER kismon

ENTRYPOINT ["/usr/local/bin/kismon-entrypoint.sh"]
