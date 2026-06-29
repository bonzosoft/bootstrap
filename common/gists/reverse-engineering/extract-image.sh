#!/bin/bash

set -e

IMAGE="$1"

if [ -z "$IMAGE" ]; then
    echo "Uso: $0 <imagen>"
    exit 1
fi

WORKDIR="recovered-image"

echo "[+] Creando estructura..."
mkdir -p ${WORKDIR}/config/postfix
mkdir -p ${WORKDIR}/config/opendkim
mkdir -p ${WORKDIR}/certs

echo "[+] Creando contenedor temporal..."
CID=$(docker create ${IMAGE})

cleanup() {
    docker rm -f ${CID} >/dev/null 2>&1 || true
}

trap cleanup EXIT

echo "[+] Extrayendo configuración postfix..."
docker cp ${CID}:/etc/postfix/main.cf ${WORKDIR}/config/main.cf || true
docker cp ${CID}:/etc/postfix/master.cf ${WORKDIR}/config/master.cf || true

echo "[+] Extrayendo configuración opendkim..."
docker cp ${CID}:/etc/opendkim.conf ${WORKDIR}/config/opendkim.conf || true
docker cp ${CID}:/etc/opendkim ${WORKDIR}/config/ || true

echo "[+] Extrayendo scripts..."
docker cp ${CID}:/docker-entrypoint.sh ${WORKDIR}/docker-entrypoint.sh || true
docker cp ${CID}:/usr/local/bin/certgen.sh ${WORKDIR}/certs/certgen.sh || true

echo "[+] Extrayendo plantillas SSL..."
docker cp ${CID}:/etc/ssl/postfix-openssl.cnf.tpl ${WORKDIR}/certs/ || true
docker cp ${CID}:/etc/ssl/ca-openssl.cnf.tpl ${WORKDIR}/certs/ || true

echo "[+] Extrayendo certificados opcionales..."
docker cp ${CID}:/etc/ssl ${WORKDIR}/ssl || true

echo "[+] Listo."
echo "[+] Archivos recuperados en: ${WORKDIR}"