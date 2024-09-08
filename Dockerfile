ARG CADDY_VERSION="v2.7.5"

FROM golang:1.22-alpine AS builder
ARG CADDY_VERSION
ENV CADDY_VERSION=${CADDY_VERSION}
ENV XCADDY_SKIP_CLEANUP=1
ENV XCADDY_GO_BUILD_FLAGS="-trimpath -ldflags='-s -w'"

RUN apk add --no-cache git

WORKDIR /builder
COPY ./ /builder
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

RUN xcaddy build \
    --with github.com/caddy-dns/alidns \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/greenpau/caddy-security \
    --output /builder/bin/caddy

FROM alpine:3.14

ENV TZ=Asia/Shanghai

RUN addgroup -S caddy && \
    adduser -D -S -s /sbin/nologin -G caddy caddy && \
    mkdir -p /etc/caddy /usr/share/caddy /var/lib/caddy && \
    chown -R caddy:caddy /etc/caddy /usr/share/caddy /var/lib/caddy \
    && apk add --no-cache --virtual .build-deps \
    curl \
    ca-certificates \
    openssl \
    tzdata \
    && update-ca-certificates \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/* \
    && cp /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

USER caddy

COPY --from=builder /builder/bin/caddy /usr/bin/caddy

EXPOSE 80 443 2015

ENTRYPOINT ["/usr/bin/caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]