if [ $# -gt 0 ]; then
    # Script Mode
    docker run \
        --rm \
        -i \
        -v /etc:/host/etc:ro \
        -v /mnt/tank0/apps:/mnt/tank0/apps:rw \
        #-v /var/run/docker.sock:/var/run/docker.sock:ro \
        -w ${PWD} \
        ghcr.io/bonzosoft/pwsh pwsh -NoLogo -NoProfile -Command "$@" -InformationAction Continue
else
    # Interactive Mode
    docker run \
        --rm \
        -it \
        -v /etc:/host/etc:ro \
        -v /mnt/tank0/apps:/mnt/tank0/apps:rw \
        #-v /var/run/docker.sock:/var/run/docker.sock:ro \
        -w ${PWD} \
        ghcr.io/bonzosoft/pwsh pwsh -NoLogo -NoProfile
fi
