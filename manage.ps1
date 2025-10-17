# ========================================
# LoginTester - Script de Gerenciamento Unificado
# Funciona tanto localmente quanto externamente
# ========================================

param(
    [Parameter(Position=0)]
    [ValidateSet("start", "stop", "restart", "logs", "status", "clean", "db", "ngrok", "test", "help")]
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
    Write-Host "  test          - Executa todos os testes (backend, frontend, integração)" -ForegroundColor $White
    Write-Host "  help          - Mostra esta ajuda" -ForegroundColor $White
    Write-Host ""
    Write-Host "Exemplos:" -ForegroundColor $Cyan
    Write-Host "  .\manage.ps1 start" -ForegroundColor $White
    Write-Host "  .\manage.ps1 logs backend" -ForegroundColor $White
    Write-Host "  .\manage.ps1 test" -ForegroundColor $White
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

# ========================================
# FUNÇÕES DE TESTE
# ========================================

function Run-Tests {
    Write-Host "=== Executando Testes do LoginTester ===" -ForegroundColor $Green
    Write-Host ""
    
    # Verificar se o sistema está rodando
    Write-Host "Verificando se o sistema esta rodando..." -ForegroundColor $Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/swagger-ui.html" -Method GET -UseBasicParsing -TimeoutSec 5
        Write-Host "SUCCESS Sistema esta rodando!" -ForegroundColor $Green
    } catch {
        Write-Host "ERROR Sistema nao esta rodando!" -ForegroundColor $Red
        Write-Host "Execute '.\manage.ps1 start' primeiro para iniciar o sistema" -ForegroundColor $Yellow
        return
    }
    
    Write-Host ""
    
    # Contadores de resultados
    $script:BackendTests = 0
    $script:BackendPassed = 0
    $script:FrontendTests = 0
    $script:FrontendPassed = 0
    $script:IntegrationTests = 0
    $script:IntegrationPassed = 0
    
    # Executar testes do Backend
    Test-Backend
    
    # Executar testes do Frontend
    Test-Frontend
    
    # Executar testes de Integração
    Test-Integration
    
    # Mostrar resumo final
    Show-TestSummary
}

function Test-Backend {
    Write-Host "=== TESTES DO BACKEND (Spring Boot) ===" -ForegroundColor $Cyan
    
    try {
        Write-Host "Executando testes do backend via Docker..." -ForegroundColor $Yellow
        $mvnOutput = docker-compose exec -T backend mvn test 2>&1
        
        # Parse dos resultados
        $testResults = $mvnOutput | Select-String "Tests run: (\d+), Failures: (\d+), Errors: (\d+), Skipped: (\d+)"
        
        if ($testResults) {
            $matches = $testResults.Matches[0]
            $script:BackendTests = [int]$matches.Groups[1].Value
            $failures = [int]$matches.Groups[2].Value
            $errors = [int]$matches.Groups[3].Value
            $skipped = [int]$matches.Groups[4].Value
            
            $script:BackendPassed = $script:BackendTests - $failures - $errors
            
            if ($failures -eq 0 -and $errors -eq 0) {
                Write-Host "SUCCESS Backend: $($script:BackendPassed)/$($script:BackendTests) testes passaram" -ForegroundColor $Green
            } else {
                Write-Host "ERROR Backend: $($script:BackendPassed)/$($script:BackendTests) testes passaram" -ForegroundColor $Red
                Write-Host "  Falhas: $failures, Erros: $errors" -ForegroundColor $Yellow
            }
        } else {
            Write-Host "WARNING: Nao foi possivel parsear os resultados dos testes do backend" -ForegroundColor $Yellow
        }
    } catch {
        Write-Host "ERROR: Erro ao executar testes do backend: $($_.Exception.Message)" -ForegroundColor $Red
    }
    
    Write-Host ""
}

function Test-Frontend {
    Write-Host "=== TESTES DO FRONTEND (React + Vitest) ===" -ForegroundColor $Cyan
    
    try {
        Write-Host "Executando testes do frontend via Docker..." -ForegroundColor $Yellow
        $npmOutput = docker-compose exec -T frontend npm test -- --run 2>&1
        
        # Parse dos resultados
        $testResults = $npmOutput | Select-String 'Tests\s+(\d+)\s+passed\s+\((\d+)\)'
        
        if ($testResults) {
            $matches = $testResults.Matches[0]
            $script:FrontendTests = [int]$matches.Groups[2].Value
            $script:FrontendPassed = [int]$matches.Groups[1].Value
            
            if ($script:FrontendPassed -eq $script:FrontendTests) {
                Write-Host "SUCCESS Frontend: $($script:FrontendPassed)/$($script:FrontendTests) testes passaram" -ForegroundColor $Green
            } else {
                Write-Host "ERROR Frontend: $($script:FrontendPassed)/$($script:FrontendTests) testes passaram" -ForegroundColor $Red
            }
        } else {
            # Fallback para outro formato
            $testResults = $npmOutput | Select-String 'Test Files\s+(\d+)\s+(failed|passed)\s+\|\s+(\d+)\s+passed\s+\((\d+)\)'
            if ($testResults) {
                $matches = $testResults.Matches[0]
                $script:FrontendTests = [int]$matches.Groups[4].Value
                $script:FrontendPassed = [int]$matches.Groups[3].Value
                
                if ($script:FrontendPassed -eq $script:FrontendTests) {
                    Write-Host "SUCCESS Frontend: $($script:FrontendPassed)/$($script:FrontendTests) testes passaram" -ForegroundColor $Green
                } else {
                    Write-Host "ERROR Frontend: $($script:FrontendPassed)/$($script:FrontendTests) testes passaram" -ForegroundColor $Red
                }
            } else {
                Write-Host "WARNING: Nao foi possivel parsear os resultados dos testes do frontend" -ForegroundColor $Yellow
            }
        }
    } catch {
        Write-Host "ERROR: Erro ao executar testes do frontend: $($_.Exception.Message)" -ForegroundColor $Red
    }
    
    Write-Host ""
}

function Test-Integration {
    Write-Host "=== TESTES DE INTEGRAÇÃO (API + Sistema) ===" -ForegroundColor $Cyan
    
    $script:IntegrationTests = 5
    $script:IntegrationPassed = 0
    
    # TESTE 1: Verificar se API está respondendo
    Write-Host "Testando se API esta respondendo..." -ForegroundColor $Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/swagger-ui.html" -Method GET -UseBasicParsing
        Write-Host "SUCCESS API esta respondendo" -ForegroundColor $Green
        $script:IntegrationPassed++
    } catch {
        Write-Host "ERROR API nao esta respondendo: $($_.Exception.Message)" -ForegroundColor $Red
    }
    
    # TESTE 2: Registro de usuário
    Write-Host "Testando registro de usuario..." -ForegroundColor $Yellow
    try {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $uniqueEmail = "test$timestamp@logintester.com"
        
        $registerBody = @{
            name = "Test User"
            email = $uniqueEmail
            password = "Test123!"
            confirmPassword = "Test123!"
        } | ConvertTo-Json

        $registerResponse = Invoke-WebRequest -Uri "http://localhost:8080/auth/register" -Method POST -Body $registerBody -ContentType "application/json" -UseBasicParsing
        Write-Host "SUCCESS Registro de usuario OK" -ForegroundColor $Green
        $script:IntegrationPassed++
    } catch {
        Write-Host "ERROR Registro de usuario falhou: $($_.Exception.Message)" -ForegroundColor $Red
    }
    
    # TESTE 3: Login de usuário
    Write-Host "Testando login de usuário..." -ForegroundColor $Yellow
    try {
        $loginBody = @{
            email = "user@mail.com"
            password = "user123"
        } | ConvertTo-Json

        $loginResponse = Invoke-WebRequest -Uri "http://localhost:8080/auth/login" -Method POST -Body $loginBody -ContentType "application/json" -UseBasicParsing
        
        if ($loginResponse.Content -like "*Login realizado com sucesso*") {
            Write-Host "SUCCESS Login de usuario OK" -ForegroundColor $Green
            $script:IntegrationPassed++
        } else {
            Write-Host "ERROR Login de usuario falhou" -ForegroundColor $Red
        }
    } catch {
        Write-Host "ERROR Login de usuario falhou: $($_.Exception.Message)" -ForegroundColor $Red
    }
    
    # TESTE 4: Login como admin
    Write-Host "Testando login de admin..." -ForegroundColor $Yellow
    try {
        $adminLoginBody = @{
            email = "admin@mail.com"
            password = "admin123"
        } | ConvertTo-Json

        $adminLoginResponse = Invoke-WebRequest -Uri "http://localhost:8080/auth/login" -Method POST -Body $adminLoginBody -ContentType "application/json" -UseBasicParsing -SessionVariable "adminSession"
        
        if ($adminLoginResponse.Content -like "*Login realizado com sucesso*") {
            Write-Host "SUCCESS Login de admin OK" -ForegroundColor $Green
            $script:IntegrationPassed++
        } else {
            Write-Host "ERROR Login de admin falhou" -ForegroundColor $Red
        }
    } catch {
        Write-Host "ERROR Login de admin falhou: $($_.Exception.Message)" -ForegroundColor $Red
    }
    
    # TESTE 5: API de segurança
    Write-Host "Testando API de seguranca..." -ForegroundColor $Yellow
    try {
        $securityResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/security/dashboard" -Method GET -WebSession $adminSession -UseBasicParsing
        
        if ($securityResponse.Content -like "*totalLoginsToday*") {
            Write-Host "SUCCESS API de seguranca OK" -ForegroundColor $Green
            $script:IntegrationPassed++
        } else {
            Write-Host "ERROR API de seguranca falhou" -ForegroundColor $Red
        }
    } catch {
        Write-Host "ERROR API de seguranca falhou: $($_.Exception.Message)" -ForegroundColor $Red
    }
    
    Write-Host ""
}

function Show-TestSummary {
    Write-Host "=== RESUMO FINAL DOS TESTES ===" -ForegroundColor $Cyan
    Write-Host "===============================" -ForegroundColor $Cyan
    Write-Host ""
    
    $totalTests = $script:BackendTests + $script:FrontendTests + $script:IntegrationTests
    $totalPassed = $script:BackendPassed + $script:FrontendPassed + $script:IntegrationPassed
    
    Write-Host "Backend (Spring Boot):" -ForegroundColor $Yellow
    Write-Host "   Testes: $($script:BackendPassed)/$($script:BackendTests)" -ForegroundColor $White
    
    Write-Host "Frontend (React + Vitest):" -ForegroundColor $Yellow
    Write-Host "   Testes: $($script:FrontendPassed)/$($script:FrontendTests)" -ForegroundColor $White
    
    Write-Host "Integração (API + Sistema):" -ForegroundColor $Yellow
    Write-Host "   Testes: $($script:IntegrationPassed)/$($script:IntegrationTests)" -ForegroundColor $White
    
    Write-Host ""
    Write-Host "TOTAL GERAL:" -ForegroundColor $Cyan
    Write-Host "   Testes: $totalPassed/$totalTests" -ForegroundColor $White
    
    $successRate = if ($totalTests -gt 0) { [math]::Round(($totalPassed / $totalTests) * 100, 2) } else { 0 }
    Write-Host "   Taxa de Sucesso: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { $Green } elseif ($successRate -ge 70) { $Yellow } else { $Red })
    
    Write-Host ""
    if ($totalPassed -eq $totalTests) {
        Write-Host "TODOS OS TESTES PASSARAM!" -ForegroundColor $Green
        Write-Host "   Sistema esta funcionando perfeitamente!" -ForegroundColor $Green
    } elseif ($successRate -ge 90) {
        Write-Host "EXCELENTE! Quase todos os testes passaram!" -ForegroundColor $Green
        Write-Host "   Sistema esta funcionando muito bem!" -ForegroundColor $Green
    } elseif ($successRate -ge 70) {
        Write-Host "BOM! Maioria dos testes passou!" -ForegroundColor $Yellow
        Write-Host "   Sistema esta funcionando, mas ha melhorias a fazer!" -ForegroundColor $Yellow
    } else {
        Write-Host "ATENCAO! Muitos testes falharam!" -ForegroundColor $Red
        Write-Host "   Sistema precisa de correcoes!" -ForegroundColor $Red
    }
    
    Write-Host ""
    Write-Host "Para mais detalhes:" -ForegroundColor $Blue
    Write-Host "  - Execute '.\manage.ps1 logs backend' para logs do backend" -ForegroundColor $White
    Write-Host "  - Execute '.\manage.ps1 logs frontend' para logs do frontend" -ForegroundColor $White
    Write-Host "  - Acesse http://localhost:8080/swagger-ui.html para testar APIs" -ForegroundColor $White
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
    "test" { Run-Tests }
    "help" { Show-Help }
    default { Show-Help }
}