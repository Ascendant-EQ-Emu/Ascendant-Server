FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    cron \
    mariadb-client \
    gzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash eqemu

COPY backup.sh /usr/local/bin/backup.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/backup.sh /usr/local/bin/entrypoint.sh

RUN mkdir -p /backups && chown eqemu:eqemu /backups

ENTRYPOINT ["entrypoint.sh"]
