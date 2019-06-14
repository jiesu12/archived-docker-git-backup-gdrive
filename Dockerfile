ARG arch
FROM alpine:3.8

RUN apk --no-cache add bash busybox-suid tzdata p7zip git curl && \
ln -snf /usr/share/zoneinfo/America/Chicago /etc/localtime && \
echo 'America/Chicago' > /etc/timezone && \
addgroup -g 1000 jie && adduser -D -G jie -u 1000 jie && \
mkdir /log && chown jie:jie /log

VOLUME /repos
VOLUME /log

COPY job.sh /
RUN chmod +x /job.sh

USER jie
ENTRYPOINT ["/job.sh"]

