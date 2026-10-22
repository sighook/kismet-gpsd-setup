FROM finchsec/kismet:latest

COPY entrypoint.sh /usr/local/bin/kismet-entrypoint.sh
RUN chmod +x /usr/local/bin/kismet-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/kismet-entrypoint.sh"]
