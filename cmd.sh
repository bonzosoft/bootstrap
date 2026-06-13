#!/usr/bin/env pwsh

if [ $# -gt 0 ]; then
    # Command Mode
    docker run \
        --rm \
        -i \
        #-v /var/run/docker.sock:/var/run/docker.sock:ro \
        -v /etc:/host/etc:ro \
        -v /mnt/tank0/apps:/mnt/tank0/apps:rw \
        -w ${PWD} \
        ghcr.io/bonzosoft/pwsh pwsh -NoLogo -NoProfile -Command "$@" -InformationAction Continue
else
    # Interactive Mode
    docker run \
        --rm \
        -it \
        #-v /var/run/docker.sock:/var/run/docker.sock:ro \
        -v /etc:/host/etc:ro \
        -v /mnt/tank0/apps:/mnt/tank0/apps:rw \
        -w ${PWD} \
        ghcr.io/bonzosoft/pwsh pwsh -NoLogo -NoProfile
fi
