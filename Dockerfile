FROM alpine:latest as base
MAINTAINER Nils Magnus Eliassen (nils@eliassen.io)
ENV VERSION=202304120728
ENV TAC_PLUS_BIN=/tacacs/sbin/tac_plus-ng
ENV CONF_FILE=/etc/tac_plus/tac_plus.cfg


FROM base as build
RUN apk add --no-cache \
    build-base bzip2 perl pcre-dev perl-digest-md5 perl-ldap git
RUN cd /
ADD https://raw.githubusercontent.com/thegoggel/tac_plus-ng-docker/main/entrypoint.sh /entrypoint.sh
RUN git clone https://github.com/MarcJHuber/event-driven-servers && \
    cd event-driven-servers && \
    ./configure --prefix=/tacacs --with-pcre && \
    make && \
    make install


FROM base
COPY --from=build /tacacs /tacacs
COPY --from=build /entrypoint.sh /entrypoint.sh
COPY --from=build /event-driven-servers/tac_plus-ng/sample/tac_plus-ng.cfg $CONF_FILE
COPY --from=build /tacacs/lib/mavis/mavis_tacplus_ldap.pl /usr/local/lib/mavis/mavis_tacplus_ldap.pl
RUN apk add --no-cache perl perl-digest-md5 perl-ldap pcre-dev && \
    chmod u+x /entrypoint.sh
EXPOSE 49
ENTRYPOINT ["/entrypoint.sh"]
