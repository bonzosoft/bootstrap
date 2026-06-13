
wget https://raw.githubusercontent.com/bonzosoft/bootstrap/pruebas/bootstrap.ps1 && \
docker run --rm -it -v /etc:/host/etc:ro -v ${PWD}:${PWD}:rw -w ${PWD} ghcr.io/bonzosoft/pwsh pwsh -NoLogo -NoProfile -File ./bootstrap.ps1 -InformationAction Continue && \
rm ./bootstrap.ps1