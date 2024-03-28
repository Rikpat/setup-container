FROM alpine
RUN \
  apk --update --no-cache upgrade && \
  apk add --update --no-cache libintl gettext

COPY scripts /scripts
WORKDIR /scripts

ENV PUID=1000
ENV PGID=1000

RUN chmod 555 /scripts/*.sh

ENTRYPOINT ["/scripts/entrypoint.sh"]
CMD ["/scripts/envsubst.sh"]