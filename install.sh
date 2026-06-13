#!/usr/bin/env pwsh

# Script Mode
#-v /var/run/docker.sock:/var/run/docker.sock:ro \
docker run \
    --rm \
    -it \
    -v /etc:/host/etc:ro \
    -v /mnt/tank0/apps:/mnt/tank0/apps:rw \
    -w ${PWD} \
    ghcr.io/bonzosoft/pwsh pwsh -NoLogo -NoProfile -File ${PWD}/common/install.ps1 -InformationAction Continue
