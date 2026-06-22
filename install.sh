#!/bin/bash

# Script Mode
docker run \
    --rm \
    -it \
    -v /etc:/host/etc:ro \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -v /mnt/tank0/apps:/mnt/tank0/apps:rw \
    -w ${PWD} \
    ghcr.io/bonzosoft/pwsh pwsh -NoLogo -NoProfile -File ${PWD}/common/install.ps1 -InformationAction Continue
