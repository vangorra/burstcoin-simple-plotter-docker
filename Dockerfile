FROM vangorra/burstcoin-plotter-docker

COPY entrypoint.sh /usr/local/bin

RUN apk --no-cache add bash findmnt

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
