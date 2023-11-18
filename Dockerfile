FROM hakito/nginx-digest:1.25.2
LABEL maintainer="Hakito (https://github.com/hakito)"

ENV S6_OVERLAY_VERSION  2.1.0.2

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-amd64-installer /tmp/
RUN chmod +x /tmp/s6-overlay-amd64-installer \
    && /tmp/s6-overlay-amd64-installer / \
    && rm -r /tmp/s6-overlay-amd64-installer

ENV ENVPLATE_SHA256 8366c3c480379dc325dea725aac86212c5f5d1bf55f5a9ef8e92375f42d55a41
ENV CLOUDFLARE_V4_SHA256 db746a8739a51088c27d0b3c48679d21a69aab304d4c92af3ec0e89145b0cadd
ENV CLOUDFLARE_V6_SHA256 559b5c5a20088758b4643621ae80be0a71567742ae1fe8e4ff32d1ca26297f8f

RUN apk --update add --no-cache pwgen curl \
    && echo "---> INSTALLING envplate" \
    && wget https://github.com/kreuzwerker/envplate/releases/download/v0.0.8/ep-linux \
    && echo "$ENVPLATE_SHA256  ep-linux" | sha256sum -c \
    && chmod +x ep-linux \
    && mv ep-linux /usr/local/bin/ep \
    && echo "---> CREATING CloudFlare Config Snippet (not included in config by default)" \
    && echo '#Cloudflare' > /etc/nginx/cloudflare.conf \
    && wget https://www.cloudflare.com/ips-v4 \
    && sort ips-v4 > ips-v4.sorted \
    && echo "$CLOUDFLARE_V4_SHA256  ips-v4.sorted" | sha256sum -c \
    && cat ips-v4 | sed -e 's/^/set_real_ip_from /' -e 's/$/;/' >> /etc/nginx/cloudflare.conf \
    && wget https://www.cloudflare.com/ips-v6 \
    && sort ips-v6 > ips-v6.sorted \
    && echo "$CLOUDFLARE_V6_SHA256  ips-v6.sorted" | sha256sum -c \
    && cat ips-v6 | sed -e 's/^/set_real_ip_from /' -e 's/$/;/' >> /etc/nginx/cloudflare.conf \
    && rm ips-v6 ips-v4 ips-v6.sorted ips-v4.sorted \
    && echo "---> Creating directories" \
    && touch /etc/nginx/auth_part1.conf \
             /etc/nginx/auth_part2.conf \
             /etc/nginx/request_size.conf \
             /etc/nginx/main_location.conf \
             /etc/nginx/trusted_proxies.conf \
             /tmp/passwd.digest

COPY services.d/nginx/* /etc/services.d/nginx/

COPY nginx.conf security_headers.conf hsts.conf /etc/nginx/
COPY proxy.conf /etc/nginx/conf.d/default.conf
COPY auth_part*.conf /root/
COPY dhparams.pem /etc/nginx/
COPY temp-setup-cert.pem /etc/nginx/temp-server-cert.pem
COPY temp-setup-key.pem /etc/nginx/temp-server-key.pem

VOLUME "/certs"

ENTRYPOINT ["/init"]
