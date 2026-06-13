#!/bin/bash

wget -qO ${PWD}/bootstrap.ps1 https://raw.githubusercontent.com/bonzosoft/bootstrap/pruebas/bootstrap.ps1 && docker run --rm -it -v /etc:/host/etc:ro -v ${PWD}:${PWD}:rw -w ${PWD} ghcr.io/bonzosoft/pwsh pwsh -NoLogo -NoProfile -File ${PWD}/bootstrap.ps1  && rm ${PWD}/bootstrap.ps1