FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends gpsd gpsd-clients \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 2947/tcp 29998/udp

CMD ["gpsd", "-N", "-G", "-F", "/var/run/gpsd.sock", "udp://*:29998"]
