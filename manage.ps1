# ========================================
# LoginTester - Script de Gerenciamento Unificado
# Funciona tanto localmente quanto externamente
# ========================================

param(
    [Parameter(Position=0)]
    [ValidateSet("start", "stop", "restart", "logs", "status", "clean", "db", "ngrok", "help")]
    [string]$Action = "start",
    
    [Parameter(Position=1)]
    [string]$Service = ""
)

# Cores para output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"
$Cyan = "Cyan"
$White = "White"

function Show-Help {
    Write-Host "=== LoginTester Management Script ===" -ForegroundColor $Green
    Write-Host ""
    Write-Host "Uso: .\manage.ps1 [AÇÃO] [SERVIÇO]" -ForegroundColor $Yellow
    Write-Host ""
    Write-Host "Ações disponíveis:" -ForegroundColor $Cyan
    Write-Host "  start         - Inicia todos os serviços" -ForegroundColor $White
    Write-Host "  stop          - Para todos os serviços" -ForegroundColor $White
    Write-Host "  restart       - Reinicia todos os serviços" -ForegroundColor $White
    Write-Host "  logs          - Mostra logs dos serviços" -ForegroundColor $White
    Write-Host "  status        - Mostra status dos containers" -ForegroundColor $White
    Write-Host "  clean         - Remove containers e volumes (reset completo)" -ForegroundColor $White
    Write-Host "  db            - Acessa o banco de dados" -ForegroundColor $White
    Write-Host "  ngrok         - Gerencia o ngrok (start/stop/status)" -ForegroundColor $White
    Write-Host "  help          - Mostra esta ajuda" -ForegroundColor $White
    Write-Host ""
    Write-Host "Exemplos:" -ForegroundColor $Cyan
    Write-Host "  .\manage.ps1 start" -ForegroundColor $White
    Write-Host "  .\manage.ps1 logs backend" -ForegroundColor $White
    Write-Host "  .\manage.ps1 clean" -ForegroundColor $White
    Write-Host ""
    Write-Host "Acesso:" -ForegroundColor $Cyan
    Write-Host "  Local: http://localhost" -ForegroundColor $White
    Write-Host "  Externo: Use 'ngrok http localhost' para HTTPS" -ForegroundColor $White
}

function Create-EnvIfNeeded {
    if (-not (Test-Path ".env")) {
        Write-Host "Criando arquivo .env..." -ForegroundColor $Yellow
        Copy-Item "env.example" ".env"
        Write-Host "Arquivo .env criado! Edite as configurações conforme necessário." -ForegroundColor $Green
    }
}

function Start-Services {
    Write-Host "=== Iniciando LoginTester ===" -ForegroundColor $Green
    Create-EnvIfNeeded
    
    Write-Host "Iniciando todos os serviços..." -ForegroundColor $Yellow
    docker-compose up --build -d
    
    Write-Host "Aguardando serviços ficarem prontos..." -ForegroundColor $Yellow
    Start-Sleep -Seconds 10
    
    # Tentar iniciar ngrok automaticamente
    Write-Host "Verificando ngrok..." -ForegroundColor $Yellow
    try {
        $tunnels = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -ErrorAction Stop
        if ($tunnels.tunnels.Count -eq 0) {
            Write-Host "Iniciando ngrok automaticamente..." -ForegroundColor $Yellow
            Start-Ngrok
        } else {
            Write-Host "Ngrok já está rodando!" -ForegroundColor $Green
        }
    } catch {
        Write-Host "Iniciando ngrok automaticamente..." -ForegroundColor $Yellow
        Start-Ngrok
    }
    
    Write-Host "=== Sistema iniciado com sucesso! ===" -ForegroundColor $Green
    
    # Mostrar links disponíveis
    Write-Host ""
    Write-Host "=== URLs disponíveis ===" -ForegroundColor $Cyan
    Write-Host "Frontend (local): http://localhost" -ForegroundColor $White
    Write-Host "Frontend (porta): http://localhost:3000" -ForegroundColor $White
    Write-Host "Backend: http://localhost:8080" -ForegroundColor $White
    Write-Host "Swagger: http://localhost:8080/swagger-ui.html" -ForegroundColor $White
    
    # Verificar se existe link externo configurado
    if (Test-Path ".env") {
        $envContent = Get-Content ".env" -Raw
        if ($envContent -match "NGROK_DOMAIN=(.+)") {
            $ngrokDomain = $matches[1].Trim()
            if ($ngrokDomain -and $ngrokDomain -ne "") {
                Write-Host ""
                Write-Host "=== Link Externo (HTTPS) ===" -ForegroundColor $Cyan
                Write-Host "Frontend: $ngrokDomain" -ForegroundColor $White
                Write-Host "Backend: $ngrokDomain/api" -ForegroundColor $White
                Write-Host "Swagger: $ngrokDomain/api/swagger-ui.html" -ForegroundColor $White
            }
        }
    }
    
    Write-Host ""
    Write-Host "=== Credenciais de teste ===" -ForegroundColor $Cyan
    Write-Host "Admin: admin@mail.com / admin123" -ForegroundColor $White
    Write-Host "User: user@mail.com / user123" -ForegroundColor $White
    Write-Host "Unverified: unverified@mail.com / unverified123" -ForegroundColor $White
    Write-Host "Kenzo: gkenzo@gmail.com / kenzo123" -ForegroundColor $White
    
    Write-Host ""
    Write-Host "Execute '.\manage.ps1 status' para ver mais detalhes" -ForegroundColor $Yellow
}

function Stop-Services {
    Write-Host "=== Parando LoginTester ===" -ForegroundColor $Red
    docker-compose down
    Write-Host "Sistema parado!" -ForegroundColor $Green
}

function Restart-Services {
    Write-Host "=== Reiniciando LoginTester ===" -ForegroundColor $Yellow
    Stop-Services
    Start-Sleep -Seconds 2
    Start-Services
}

function Show-Logs {
    if ($Service) {
        Write-Host "=== Logs do serviço: $Service ===" -ForegroundColor $Green
        docker-compose logs -f $Service
    } else {
        Write-Host "=== Logs de todos os serviços ===" -ForegroundColor $Green
        docker-compose logs -f
    }
}

function Show-Status {
    Write-Host "=== Status dos containers ===" -ForegroundColor $Green
    docker-compose ps
    
    Write-Host ""
    Write-Host "=== URLs disponíveis ===" -ForegroundColor $Cyan
    Write-Host "Frontend (local): http://localhost" -ForegroundColor $White
    Write-Host "Frontend (porta): http://localhost:3000" -ForegroundColor $White
    Write-Host "Backend: http://localhost:8080" -ForegroundColor $White
    Write-Host "Swagger: http://localhost:8080/swagger-ui.html" -ForegroundColor $White
    Write-Host "Database: localhost:5432" -ForegroundColor $White
    
    # Verificar se existe link externo configurado
    if (Test-Path ".env") {
        $envContent = Get-Content ".env" -Raw
        if ($envContent -match "NGROK_DOMAIN=(.+)") {
            $ngrokDomain = $matches[1].Trim()
            if ($ngrokDomain -and $ngrokDomain -ne "") {
                Write-Host ""
                Write-Host "=== Link Externo (HTTPS) ===" -ForegroundColor $Cyan
                Write-Host "Frontend: $ngrokDomain" -ForegroundColor $White
                Write-Host "Backend: $ngrokDomain/api" -ForegroundColor $White
                Write-Host "Swagger: $ngrokDomain/api/swagger-ui.html" -ForegroundColor $White
            }
        }
    }
    
    Write-Host ""
    Write-Host "=== Para acesso externo ===" -ForegroundColor $Cyan
    Write-Host "Execute: ngrok http localhost" -ForegroundColor $White
    Write-Host "Depois acesse o link HTTPS fornecido pelo ngrok" -ForegroundColor $White
    Write-Host ""
    Write-Host "=== Credenciais de teste ===" -ForegroundColor $Cyan
    Write-Host "Admin: admin@mail.com / admin123" -ForegroundColor $White
    Write-Host "User: user@mail.com / user123" -ForegroundColor $White
    Write-Host "Unverified: unverified@mail.com / unverified123" -ForegroundColor $White
    Write-Host "Kenzo: gkenzo@gmail.com / kenzo123" -ForegroundColor $White
}

function Clean-System {
    Write-Host "=== Limpeza Completa do Sistema ===" -ForegroundColor $Red
    Write-Host "ATENÇÃO: Esta operação irá remover TODOS os containers, volumes e dados!" -ForegroundColor $Yellow
    Write-Host "Digite 'yes' para confirmar ou qualquer outra coisa para cancelar:" -ForegroundColor $Yellow
    $confirm = Read-Host
    
    if ($confirm -eq "yes") {
        Write-Host "Removendo containers e volumes..." -ForegroundColor $Yellow
        docker-compose down -v
        docker system prune -f
        Write-Host "Limpeza concluída! Execute '.\manage.ps1 start' para reiniciar." -ForegroundColor $Green
    } else {
        Write-Host "Operação cancelada." -ForegroundColor $Yellow
    }
}

function Access-Database {
    Write-Host "Acessando banco de dados PostgreSQL..." -ForegroundColor $Blue
    Write-Host "Digite '\q' para sair do psql" -ForegroundColor $Yellow
    Write-Host ""
    
    docker-compose exec database psql -U logintester_admin -d logintester_db
}

function Manage-Ngrok {
    if ($Service -eq "start") {
        Start-Ngrok
    } elseif ($Service -eq "stop") {
        Stop-Ngrok
    } elseif ($Service -eq "status") {
        Show-NgrokStatus
    } else {
        Write-Host "=== Gerenciamento do Ngrok ===" -ForegroundColor $Green
        Write-Host ""
        Write-Host "Comandos disponíveis:" -ForegroundColor $Cyan
        Write-Host "  .\manage.ps1 ngrok start   - Inicia o ngrok" -ForegroundColor $White
        Write-Host "  .\manage.ps1 ngrok stop    - Para o ngrok" -ForegroundColor $White
        Write-Host "  .\manage.ps1 ngrok status  - Mostra status do ngrok" -ForegroundColor $White
        Write-Host ""
        Write-Host "O ngrok será iniciado automaticamente quando você usar '.\manage.ps1 start'" -ForegroundColor $Yellow
    }
}

function Start-Ngrok {
    Write-Host "=== Iniciando Ngrok ===" -ForegroundColor $Green
    
    # Verificar se ngrok está instalado
    try {
        $ngrokVersion = ngrok version 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Ngrok não encontrado"
        }
        Write-Host "Ngrok encontrado: $ngrokVersion" -ForegroundColor $Yellow
    } catch {
        Write-Host "ERRO: Ngrok não está instalado!" -ForegroundColor $Red
        Write-Host "Instale o ngrok em: https://ngrok.com/download" -ForegroundColor $Yellow
        return
    }
    
    # Verificar se já está rodando
    try {
        $tunnels = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -ErrorAction Stop
        if ($tunnels.tunnels.Count -gt 0) {
            Write-Host "Ngrok já está rodando!" -ForegroundColor $Yellow
            Show-NgrokStatus
            return
        }
    } catch {
        # Ngrok não está rodando, continuar
    }
    
    Write-Host "Iniciando ngrok em background..." -ForegroundColor $Yellow
    Start-Process -FilePath "ngrok" -ArgumentList "http", "localhost" -WindowStyle Hidden
    
    # Aguardar ngrok inicializar
    Write-Host "Aguardando ngrok inicializar..." -ForegroundColor $Yellow
    $maxAttempts = 30
    $attempt = 0
    
    do {
        Start-Sleep -Seconds 1
        $attempt++
        try {
            $tunnels = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -ErrorAction Stop
            if ($tunnels.tunnels.Count -gt 0) {
                Write-Host "Ngrok iniciado com sucesso!" -ForegroundColor $Green
                Show-NgrokStatus
                return
            }
        } catch {
            # Continuar tentando
        }
    } while ($attempt -lt $maxAttempts)
    
    Write-Host "ERRO: Ngrok não conseguiu inicializar em 30 segundos" -ForegroundColor $Red
}

function Stop-Ngrok {
    Write-Host "=== Parando Ngrok ===" -ForegroundColor $Red
    
    try {
        $tunnels = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -ErrorAction Stop
        if ($tunnels.tunnels.Count -eq 0) {
            Write-Host "Ngrok não está rodando" -ForegroundColor $Yellow
            return
        }
    } catch {
        Write-Host "Ngrok não está rodando" -ForegroundColor $Yellow
        return
    }
    
    # Parar processos ngrok
    $ngrokProcesses = Get-Process -Name "ngrok" -ErrorAction SilentlyContinue
    if ($ngrokProcesses) {
        $ngrokProcesses | Stop-Process -Force
        Write-Host "Ngrok parado!" -ForegroundColor $Green
    } else {
        Write-Host "Nenhum processo ngrok encontrado" -ForegroundColor $Yellow
    }
}

function Show-NgrokStatus {
    Write-Host "=== Status do Ngrok ===" -ForegroundColor $Green
    
    try {
        $tunnels = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -ErrorAction Stop
        
        if ($tunnels.tunnels.Count -eq 0) {
            Write-Host "Ngrok não está rodando" -ForegroundColor $Red
            Write-Host "Execute: .\manage.ps1 ngrok start" -ForegroundColor $Yellow
            return
        }
        
        Write-Host "Ngrok está rodando!" -ForegroundColor $Green
        Write-Host ""
        
        foreach ($tunnel in $tunnels.tunnels) {
            Write-Host "Túnel: $($tunnel.name)" -ForegroundColor $Cyan
            Write-Host "URL Pública: $($tunnel.public_url)" -ForegroundColor $White
            Write-Host "Protocolo: $($tunnel.proto)" -ForegroundColor $White
            Write-Host "Status: $($tunnel.state)" -ForegroundColor $White
            Write-Host ""
        }
        
        # Atualizar arquivo .env se necessário
        if ($tunnels.tunnels.Count -gt 0) {
            $publicUrl = $tunnels.tunnels[0].public_url
            if (Test-Path ".env") {
                $envContent = Get-Content ".env" -Raw
                if ($envContent -notmatch "NGROK_DOMAIN=$([regex]::Escape($publicUrl))") {
                    Write-Host "Atualizando arquivo .env com novo domínio..." -ForegroundColor $Yellow
                    $envContent = $envContent -replace "NGROK_DOMAIN=.*", "NGROK_DOMAIN=$publicUrl"
                    Set-Content -Path ".env" -Value $envContent
                    Write-Host "Arquivo .env atualizado!" -ForegroundColor $Green
                }
            }
        }
        
    } catch {
        Write-Host "Ngrok não está rodando ou não está acessível" -ForegroundColor $Red
        Write-Host "Execute: .\manage.ps1 ngrok start" -ForegroundColor $Yellow
    }
}

# Executar ação solicitada
switch ($Action) {
    "start" { Start-Services }
    "stop" { Stop-Services }
    "restart" { Restart-Services }
    "logs" { Show-Logs }
    "status" { Show-Status }
    "clean" { Clean-System }
    "db" { Access-Database }
    "ngrok" { Manage-Ngrok }
    "help" { Show-Help }
    default { Show-Help }
}