#!/bin/bash

# CONFIGURACIÓN
ORG="bonzosoft"
DESTINO="$HOME/Documentos/Github/"

mkdir -p "$DESTINO"
cd "$DESTINO" || exit 1

echo "Obteniendo repositorios de $ORG..."

gh repo list "$ORG" \
  --limit 1000 \
  --json name,sshUrl \
  --jq '.[] | .sshUrl' | while read -r repo; do

    nombre=$(basename "$repo" .git)

    if [ -d "$nombre/.git" ]; then
        echo "Ya existe: $nombre"
    else
        echo "Clonando $nombre..."
        git clone "$repo"
    fi
done

echo "Terminado."