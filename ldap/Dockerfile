FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Preseed debconf for slapd
RUN echo "slapd slapd/domain string attt.ptit.edu.vn" | debconf-set-selections && \
    echo "slapd slapd/admin_password password AdminPassword123!" | debconf-set-selections && \
    echo "slapd slapd/admin_password_again password AdminPassword123!" | debconf-set-selections

# Install slapd and ldap-utils
RUN apt-get update && apt-get install -y --no-install-recommends \
    slapd \
    ldap-utils \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Add memberof and refint schemas/overlays (standard for RBAC)
COPY init-ldap.ldif /etc/ldap/init-ldap.ldif
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    chown -R openldap:openldap /var/lib/ldap /etc/ldap

EXPOSE 389

ENTRYPOINT ["/entrypoint.sh"]
