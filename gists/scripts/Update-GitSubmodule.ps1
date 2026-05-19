function Update-GitSubmodule {
  [CmdletBinding()]
  param (
      [Parameter(Mandatory=$true, Position=0)]
      [string[]]$Submodule,

      [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
      [string[]]$Repo
  )

  begin {
      $allRepos = @()
      Write-Host "🚀 Iniciando actualización masiva de submódulos..." -ForegroundColor Cyan
  }

  process {
      if ($Repo) { $allRepos += $Repo }
  }

  end {
      # Si no hay repos especificados, buscamos todos los directorios locales
      if ($allRepos.Count -eq 0) {
          $allRepos = Get-ChildItem -Directory | Select-Object -ExpandProperty Name
      }

      foreach ($repoName in $allRepos) {
          $repoPath = Join-Path (Get-Location) $repoName
          
          # 1. Skip si no es un repo de Git
          if (-not (Test-Path "$repoPath\.git")) {
              Write-Host "⏭️  SKIPPING: '$repoName' (No es un repositorio Git)" -ForegroundColor Gray
              continue
          }

          Push-Location $repoPath
          Write-Host "`n📂 Repo: [$repoName]" -ForegroundColor Magenta

          foreach ($sub in $Submodule) {
              try {
                  # 2. Comprobar si existe el archivo .gitmodules
                  if (-not (Test-Path ".gitmodules")) {
                      Write-Host "   - No tiene submódulos configurados." -ForegroundColor Gray
                      break # Salimos del loop de submódulos para este repo
                  }

                  # 3. Buscar la ruta del submódulo específico
                  $submoduleEntry = git config --file .gitmodules --get-regexp path | Select-String -Pattern "$sub" -ErrorAction SilentlyContinue

                  if (-not $submoduleEntry) {
                      Write-Host "   - Submódulo '$sub' no encontrado. Saltando..." -ForegroundColor Gray
                      continue # Pasa al siguiente submódulo del array
                  }

                  # Extraer la ruta (ej: include/mi-repo)
                  $subPath = ($submoduleEntry.ToString() -split ' ')[1]
                  Write-Host "   📦 Actualizando '$sub' en: $subPath" -ForegroundColor Yellow

                  # 4. Actualización remota (IO de red)
                  git submodule update --remote -- $subPath 2>$null

                  # 5. Commit si hay cambios
                  if ($(git status --porcelain $subPath)) {
                      git add $subPath
                      git commit -m "chore(deps): update submodule $sub to latest" --quiet
                      Write-Host "     ✅ ¡Actualizado y commiteado!" -ForegroundColor Green
                  } else {
                      Write-Host "     - Ya estaba al día." -ForegroundColor Gray
                  }
              }
              catch {
                  Write-Host "   ❌ ERROR en '$repoName': $($_.Exception.Message)" -ForegroundColor Red
              }
          }
          Pop-Location
      }
      Write-Host "`n🏁 Proceso finalizado." -ForegroundColor Cyan
  }
}