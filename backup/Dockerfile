FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
      awscli mysql-client postgresql-client curl ca-certificates \
    && curl -fsSL -o /tmp/mt.deb \
       https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2204-x86_64-100.9.4.deb \
    && apt-get install -y /tmp/mt.deb \
    && rm -rf /var/lib/apt/lists/* /tmp/mt.deb
COPY backup.sh /backup.sh
RUN chmod +x /backup.sh
ENTRYPOINT ["/backup.sh"]