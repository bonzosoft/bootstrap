docker run \
    --rm \
    -it \
    -v /etc:/host/etc:ro \
    -v /mnt/tank0/apps:/mnt/tank0/apps:rw \
    -v /var/run/docker.sock:/var/run/docker.sock:rw \
    -w ${PWD} \
    ghcr.io/bonzosoft/pwsh pwsh -NoLogo -NoProfile -InformationAction Continue -Command "$@"