FROM frrouting/frr:v8.4.0

COPY ./daemons /etc/frr/daemons
COPY ./scripts/ /opt/
RUN chmod +x /opt/*.sh
