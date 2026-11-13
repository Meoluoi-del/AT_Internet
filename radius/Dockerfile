FROM freeradius/freeradius-server:latest

# Copy custom configurations
COPY clients.conf /etc/raddb/clients.conf
COPY mods-available/ldap /etc/raddb/mods-available/ldap
COPY mods-available/sql /etc/raddb/mods-available/sql
COPY sites-available/default /etc/raddb/sites-available/default

# Enable ldap and sql modules and fix permissions
RUN ln -sf /etc/raddb/mods-available/ldap /etc/raddb/mods-enabled/ldap && \
    ln -sf /etc/raddb/mods-available/sql /etc/raddb/mods-enabled/sql && \
    chown -R freerad:freerad /etc/raddb

EXPOSE 1812/udp 1813/udp

CMD ["freeradius", "-X"]
