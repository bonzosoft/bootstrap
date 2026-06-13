#!/bin/bash

if [ $# -gt 0 ]; then
    # Command Mode
    #-v /var/run/docker.sock:/var/run/docker.sock:ro \
    docker run \
        --rm \
        -i \  
        -v /etc:/host/etc:ro \
        -v /mnt/tank0/apps:/mnt/tank0/apps:rw \
        -w ${PWD} \
        ghcr.io/bonzosoft/pwsh pwsh -NoLogo -NoProfile -Command "$@" -InformationAction Continue
else
    # Interactive Mode
    #-v /var/run/docker.sock:/var/run/docker.sock:ro \
    docker run \
        --rm \
        -it \
        -v /etc:/host/etc:ro \
        -v /mnt/tank0/apps:/mnt/tank0/apps:rw \
        -w ${PWD} \
        ghcr.io/bonzosoft/pwsh pwsh -NoLogo -NoProfile
fi
