# Alpine image with some networking utilites installed
FROM alpine:latest
RUN apk add --no-cache iproute2 iputils tcpdump
