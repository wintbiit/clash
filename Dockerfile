ARG CLASH_VERSION="1.18.8"

FROM golang:1.22-alpine AS builder
ARG CLASH_VERSION

RUN apk add --no-cache wget git
WORKDIR /build

RUN wget "https://github.com/MetaCubeX/mihomo/archive/refs/tags/v${CLASH_VERSION}.zip" -O clash.zip && \
    unzip clash.zip && \
    mv mihomo-${CLASH_VERSION} clash && \
    cd clash && \
    go mod download

WORKDIR /build/clash

RUN go build -trimpath -ldflags="-s -w" -o /build/bin/clash

FROM alpine:3.14
ENV TZ=Asia/Shanghai
ENV PATH /usr/local/bin:$PATH

RUN apk add --no-cache tzdata ca-certificates && \
    cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo "${TZ}" > /etc/timezone && \
    rm -rf /var/cache/apk/*

COPY --from=builder /build/bin/clash /usr/local/bin/clash
RUN chmod +x /usr/local/bin/clash

VOLUME /etc/clash

ENTRYPOINT ["clash", "-d", "/etc/clash"]