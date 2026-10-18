# Aplica migrations 003 e 004 no banco (profile_photo_path e preferred_language).
# Use se o login falhar com erro em AuthService.authenticateUser (colunas ausentes).
# Requer: containers no ar (docker-compose up -d) e variáveis do .env (POSTGRES_*).

$ErrorActionPreference = "Stop"
$dbContainer = "logintester_db"
$dbUser = if ($env:POSTGRES_USER) { $env:POSTGRES_USER } else { "logintester_admin" }
$dbName = if ($env:POSTGRES_DB) { $env:POSTGRES_DB } else { "logintester_db" }
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$migrationsDir = Join-Path (Join-Path $scriptDir "..") "LoginTester-DB\migrations"

if (-not (Test-Path $migrationsDir)) {
    Write-Error "Pasta de migrations não encontrada: $migrationsDir"
}

foreach ($m in @("003_add_profile_photo_to_users.sql", "004_add_preferred_language_to_users.sql")) {
    $f = Join-Path $migrationsDir $m
    if (-not (Test-Path $f)) {
        Write-Warning "Arquivo não encontrado: $f"
        continue
    }
    Write-Host "Aplicando $m ..."
    Get-Content $f -Raw | docker exec -i $dbContainer psql -U $dbUser -d $dbName
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Falha ao aplicar $m"
    }
    Write-Host "OK: $m"
}

Write-Host "Migrations aplicadas. Tente o login novamente."
