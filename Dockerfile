ARG CONFIG_PATH=/etc/caddy

FROM golang:1.21-alpine AS generator

WORKDIR /builder
COPY ./ /builder

RUN go run build.go
WORKDIR /builder/out

FROM golang:1.21-alpine AS builder

WORKDIR /builder
COPY --from=generator /builder/out /builder

RUN go mod init caddy
RUN go mod tidy

RUN go build -trimpath -ldflags "-s -w" -o /builder/bin/caddy

FROM alpine:3.14
ARG CONFIG_PATH

COPY --from=builder /builder/bin/caddy /usr/bin/caddy

EXPOSE 80 443 2015

ENTRYPOINT ["/usr/bin/caddy", "run", "--config", "$CONFIG_PATH/Caddyfile", "--adapter", "caddyfile"]