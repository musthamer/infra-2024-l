FROM debian:bookworm-slim

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        apache2 \
        default-mysql-client \
        ncat \
        netcat-openbsd \
        pwgen \
    && rm -rf /var/lib/apt/lists/*

COPY docker/apache/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY docker/apache/entrypoint.sh /entrypoint.sh

RUN a2enmod cgid headers \
    && chmod +x /entrypoint.sh \
    && mkdir -p /usr/lib/cgi-bin/project_2024 /var/www/html/project_2024

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apachectl", "-D", "FOREGROUND"]