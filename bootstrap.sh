docker run \
    -it \
    -v /etc:/host/etc:ro \
    -v /mnt/tank0/apps:/mnt/tank0/apps:rw \
    -w ${PWD} \
    ghcr.io/bonzosoft/pwsh pwsh -NoLogo -NoProfile -File ./bootstrap/bootstrap.ps1 -InformationAction Continue