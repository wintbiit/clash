FROM golang:1.21-alpine AS generator

WORKDIR /builder
COPY ./ /builder

RUN go run build.go
WORKDIR /builder/out

RUN go mod init caddy && \
    go mod tidy

FROM golang:1.21-alpine AS builder

WORKDIR /builder
COPY --from=generator /builder/out/go.mod ./

RUN go mod download

COPY --from=generator /builder/out /builder

RUN go build -trimpath -ldflags "-s -w" -o /builder/bin/caddy

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