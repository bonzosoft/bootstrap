<#
$envVars = ( bash -c "set -a && source .env && compgen -v" )

foreach ($var in $envVars) {
  $value = bash -c "source .env; printf '%s' \"\$$var\""
  [System.Environment]::SetEnvironmentVariable($var, $value)
}
#>

<#
# Variables antes de source .env
$before = bash -c "compgen -v"

# Variables después de source .env
$after = bash -c "set -a && source .env && compgen -v"

# Convertir a arrays
$beforeSet = $before -split "`n"
$afterSet = $after -split "`n"

# Obtener solo las nuevas o modificadas
$diff = Compare-Object -ReferenceObject $beforeSet -DifferenceObject $afterSet |
        Where-Object { $_.SideIndicator -eq "=>" } |
        Select-Object -ExpandProperty InputObject

foreach ($var in $diff) {
  $value = bash -c "source .env; printf '%s' \"\$$var\""
  [System.Environment]::SetEnvironmentVariable($var, $value)
}
#>

# Obtener pares clave=valor antes
$before = bash -c "env" | ConvertFrom-StringData

# Obtener pares clave=valor después
$after = bash -c "set -a && source .env && env" | ConvertFrom-StringData


#$changes = @{}
$changes = [PSCustomObject]@{}
foreach ($key in $after.Keys) {
  if (-not $before.ContainsKey($key) -or $before[$key] -ne $after[$key]) {
    #[System.Environment]::SetEnvironmentVariable($key, $after[$key])
    #$changes[$key] = $after[$key]
    $changes | Add-Member -MemberType NoteProperty -Name $key -Value $after[$key]
  }
}


$changes