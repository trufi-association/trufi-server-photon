FROM eclipse-temurin:21-jre-alpine

RUN apk add --no-cache wget bzip2

WORKDIR /app

RUN wget -O photon.jar https://github.com/komoot/photon/releases/download/0.4.2/photon-0.4.2.jar

EXPOSE 2322

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:2322/api?q=test || exit 1

ENTRYPOINT ["java", "-jar", "photon.jar", "-data-dir", "/app"]
