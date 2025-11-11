FROM alpine:latest as base
LABEL maintainer="Nils Magnus Eliassen (nils@eliassen.io)"
ENV VERSION=202304120728
ENV TAC_PLUS_BIN=/tacacs/sbin/tac_plus-ng
ENV CONF_FILE=/etc/tac_plus/tac_plus.cfg

FROM base as build
RUN apk add --no-cache \
      build-base bzip2 perl pcre2-dev perl-digest-md5 perl-ldap git

# Add entrypoint early
ADD https://raw.githubusercontent.com/thegoggel/tac_plus-ng-docker/main/entrypoint.sh /entrypoint.sh

# Build event-driven-servers
RUN git clone https://github.com/MarcJHuber/event-driven-servers && \
    cd event-driven-servers && \
    ./configure --prefix=/tacacs && \
    make && make install && \
    # PCRE2 verification
    if ! ldd $TAC_PLUS_BIN | grep -q pcre2; then \
        echo "ERROR: tac_plus-ng was not built with PCRE2 support!" >&2; \
        exit 1; \
    fi

FROM base
COPY --from=build /tacacs /tacacs
COPY --from=build /entrypoint.sh /entrypoint.sh
COPY --from=build /event-driven-servers/tac_plus-ng/sample/tac_plus-ng.cfg $CONF_FILE
COPY --from=build /tacacs/lib/mavis/mavis_tacplus_ldap.pl /usr/local/lib/mavis/mavis_tacplus_ldap.pl

RUN apk add --no-cache perl perl-digest-md5 perl-ldap pcre2-dev && \
    chmod u+x /entrypoint.sh

EXPOSE 49
ENTRYPOINT ["/entrypoint.sh"]
