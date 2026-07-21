# BitWarden

cat > ./script.ps1 << 'EOF'
$uri = Read-Host -Prompt "Insert Vault uri"
$credential = Get-Credential -Title "   ### VAULT LOGIN ###" -Message "Insert credential for Vault connection"
bw logout 2>&1 | Out-Null
bw config server $uri | Out-Null
ConvertFrom-SecureString -SecureString $credential.Password -AsPlainText | bw login $credential.UserName | Out-Null
$session = ConvertFrom-SecureString -SecureString $credential.Password -AsPlainText | bw unlock --raw
$token = bw get notes TOKEN_GITHUB_READONLY_ALL --session $session
if (Test-Path -Path "./common") {Remove-Item -Path "./common" -Recurse -Force | Out-Null}
git clone --branch "bw" --single-branch "https://x-access-token:$token@github.com/bonzosoft/common.git" 
Remove-Item -Path $PSCommandPath | Out-Null
EOF
docker run --rm -it -v ${PWD}:${PWD}:rw -w ${PWD} ghcr.io/bonzosoft/pwsh pwsh -NoLogo -File "./script.ps1"



cat > ./script.ps1 << 'EOF'
$ErrorActionPreference = 'Stop'
$repository = "common"
$branch = "bw"
if (Test-Path -Path (Join-Path -Path $PWD -ChildPath @($repository))) {
    Push-Location -Path (Join-Path -Path $PWD -ChildPath @($repository))
    try {
        git fetch origin
        git checkout $branch
        git reset --hard origin/$branch
    }
    finally {
        Pop-Location
    }
}
else {
    $domain = "https://eu.infisical.com"
    $organizationId = "dd2d983e-3db8-40ea-bec4-f69a13b8566a"
    $projectId = "9b3eaa39-1cba-4239-b272-9cd10c997eed"
    $credential = Get-Credential -Title "   ### INFISICAL LOGIN ###" -Message "Insert credential for Vault connection"
    $session = infisical login --domain=$domain --email=$($credential.UserName ) --password=$($credential.Password | ConvertFrom-SecureString -AsPlainText) --organization-id=$organizationId --telemetry=false --plain
    $token = infisical secrets get PWSH_CONTENTS_READONLY_ALL --session $session --domain $domain --projectId=$projectId --plain
    git clone --branch $branch --single-branch "https://x-access-token:${token}@github.com/bonzosoft/$repository.git"
    
    Remove-Item -Path $PSCommandPath | Out-Null
}
EOF
docker run --rm -it -v ${PWD}:${PWD}:rw -w ${PWD} ghcr.io/bonzosoft/pwsh pwsh -NoLogo -File "./script.ps1"






#$Env:INFISICAL_DOMAIN = "https://eu.infisical.com"
#infisical vault set file
#infisical login --interactive --domain "https://eu.infisical.com" --organization-slug="bonzosoft" --telemetry=false --plain



infisical login --email=user@example.com --password=your-password --organization-id=your-organization-id

# Or using environment variables
export INFISICAL_EMAIL="user@example.com"
export INFISICAL_PASSWORD="your-password"
export INFISICAL_ORGANIZATION_ID="your-organization-id"
infisical login

export INFISICAL_TOKEN=$(infisical login --email user@example.com --password "your-password" --organization-id "your-organization-id" --plain --silent)

$token = infisical login --method=user --domain "https://eu.infisical.com" --organization-slug="bonzosoft" --telemetry=false --plain
$token | Set-Content -Path ./infisical-token
$token = Get-Content -Path ./infisical-token
$Env:INFISICAL_TOKEN = $token
infisical secrets get PWSH_CONTENTS_READONLY_COMMON --domain "https://eu.infisical.com" --projectId "9b3eaa39-1cba-4239-b272-9cd10c997eed" --env dev #|prod|staging

backup
Copy-Item -Path ~/.infisical -Destination /mnt/tank0/apps/stack/.infisical -Force -Recurse
Copy-Item -Path ~/infisical-keyring -Destination /mnt/tank0/apps/stack/infisical-keyring -Force -Recurse
restore
Copy-Item -Path /mnt/tank0/apps/stack/.infisical -Destination ~/.infisical -Force -Recurse
Copy-Item -Path /mnt/tank0/apps/stack/infisical-keyring -Destination ~/infisical-keyring -Force -Recurse

$var = infisical secrets get Admin --domain "https://eu.infisical.com" --projectId "9b3eaa39-1cba-4239-b272-9cd10c997eed" --path="/ast" --env=dev --plain | ConvertFrom-Json -AsHashTable

$var = infisical secrets --domain "https://eu.infisical.com" --projectId "9b3eaa39-1cba-4239-b272-9cd10c997eed" --path="/ast" --env=dev --plain | ConvertFrom-Json -AsHashTable

infisical export --format=json --output-file=secrets.json --domain "https://eu.infisical.com" --projectId "9b3eaa39-1cba-4239-b272-9cd10c997eed" --path=/ast

$var = infisical export --format=json --domain "https://eu.infisical.com" --projectId "9b3eaa39-1cba-4239-b272-9cd10c997eed" --path=/ast | ConvertFrom-Json