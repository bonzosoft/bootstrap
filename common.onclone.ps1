Write-Host "Loading $PSCommandPath"


if ($IsLinux) {
    git submodule update --init --recursive --depth 1
}


Write-Host "Finishing $PSCommandPath"