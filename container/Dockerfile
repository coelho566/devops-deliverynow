FROM quay.io/keycloak/keycloak:latest AS builder

# Enable health and metrics support
ENV KC_DB=postgres
ENV KC_HOSTNAME=localhost
ENV KC_HEALTH_ENABLED=true


WORKDIR /opt/keycloak
# for demonstration purposes only, please make sure to use proper certificates in production instead
RUN keytool -genkeypair -storepass password -storetype PKCS12 -keyalg RSA -keysize 2048 -dname "CN=$KC_HOSTNAME" -alias server -ext "SAN:c=DNS:$KC_HOSTNAME,DNS:localhost,IP:127.0.0.1" -keystore conf/server.keystore
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:latest
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]