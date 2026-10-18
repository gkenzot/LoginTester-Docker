# ========================================
# LoginTester - Script de Testes Completo
# Executa todos os testes: Backend, Frontend e Integracao
# ========================================

param(
    [switch]$SkipBackend,
    [switch]$SkipFrontend,
    [switch]$SkipIntegration,
    [switch]$Verbose
)

# Cores para output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Cyan = "Cyan"
$Blue = "Blue"
$White = "White"

# Contadores globais
$script:TotalTests = 0
$script:TotalPassed = 0
$script:BackendTests = 0
$script:BackendPassed = 0
$script:FrontendTests = 0
$script:FrontendPassed = 0
$script:IntegrationTests = 0
$script:IntegrationPassed = 0

# Funcao para executar comando e capturar output
function Invoke-TestCommand {
    param($Command, $WorkingDirectory, $TestName)
    
    Write-Host "Executando: $TestName" -ForegroundColor $Yellow
    Write-Host "   Comando: $Command" -ForegroundColor $White
    Write-Host "   Diretorio: $WorkingDirectory" -ForegroundColor $White
    
    try {
        $output = Invoke-Expression "cd '$WorkingDirectory'; $Command" 2>&1
        return @{
            Success = $LASTEXITCODE -eq 0
            Output = $output
            ExitCode = $LASTEXITCODE
        }
    } catch {
        return @{
            Success = $false
            Output = $_.Exception.Message
            ExitCode = -1
        }
    }
}

# Funcao para garantir que o sistema esteja rodando (subir e parar automaticamente se necessario)
function Ensure-SystemRunning {
    Write-Host "Verificando se o sistema esta rodando..." -ForegroundColor $Yellow
    $script:StartedSystem = $false
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/swagger-ui.html" -Method GET -UseBasicParsing -TimeoutSec 5
        Write-Host "Sistema esta rodando!" -ForegroundColor $Green
        return
    } catch {
        Write-Host "Sistema nao esta rodando. Iniciando com manage.ps1..." -ForegroundColor $Yellow
        try {
            & .\manage.ps1 start | Out-Null
        } catch {
            Write-Host "Falha ao iniciar o sistema: $($_.Exception.Message)" -ForegroundColor $Red
            return
        }
        # Aguardar subir (timeout ~60s)
        $maxRetries = 30
        for ($i = 1; $i -le $maxRetries; $i++) {
            Start-Sleep -Milliseconds 2000
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:8080/swagger-ui.html" -Method GET -UseBasicParsing -TimeoutSec 3
                Write-Host "Sistema iniciado com sucesso." -ForegroundColor $Green
                $script:StartedSystem = $true
                break
            } catch {
                if ($i -eq $maxRetries) {
                    Write-Host "Timeout aguardando sistema subir." -ForegroundColor $Red
                }
            }
        }
    }
}

# Funcao para testar Backend
function Test-Backend {
    Write-Host ""
    Write-Host "=== TESTES DO BACKEND (Spring Boot + Maven) ===" -ForegroundColor $Cyan
    Write-Host "=================================================" -ForegroundColor $Cyan
    
    $backendDir = "..\LoginTester-BackEnd"
    
    # Verificar se o diretorio existe
    if (-not (Test-Path $backendDir)) {
        Write-Host "Diretorio do backend nao encontrado: $backendDir" -ForegroundColor $Red
        return
    }
    
    # Verificar se Maven Wrapper esta disponivel
    try {
        $mvnVersion = Invoke-Expression "cd '$backendDir'; .\\mvnw.cmd --version" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Maven Wrapper nao esta disponivel no projeto" -ForegroundColor $Red
            Write-Host "   Verifique a existencia do mvnw.cmd no backend" -ForegroundColor $Yellow
            return
        }
        Write-Host "Maven Wrapper encontrado" -ForegroundColor $Green
    } catch {
        Write-Host "Erro ao verificar Maven Wrapper: $($_.Exception.Message)" -ForegroundColor $Red
        return
    }
    
    # Executar testes do backend
    $result = Invoke-TestCommand -Command ".\\mvnw.cmd clean test" -WorkingDirectory $backendDir -TestName "Backend Tests"
    
    if ($result.Success) {
        Write-Host "Backend: Testes executados com sucesso" -ForegroundColor $Green
        
        # Parsear resultados do Maven - multiplos formatos
        $testResults = $result.Output | Select-String "Tests run: (\d+), Failures: (\d+), Errors: (\d+), Skipped: (\d+)"
        if (-not $testResults) {
            # Tentar formato alternativo
            $testResults = $result.Output | Select-String "Tests run: (\d+), Failures: (\d+), Errors: (\d+), Skipped: (\d+)"
        }
        if (-not $testResults) {
            # Tentar formato do Surefire
            $testResults = $result.Output | Select-String "Tests run: (\d+), Failures: (\d+), Errors: (\d+), Skipped: (\d+)"
        }
        
        if ($testResults) {
            $matches = $testResults.Matches[0]
            $script:BackendTests = [int]$matches.Groups[1].Value
            $failures = [int]$matches.Groups[2].Value
            $errors = [int]$matches.Groups[3].Value
            $skipped = [int]$matches.Groups[4].Value
            $script:BackendPassed = $script:BackendTests - $failures - $errors
            
            Write-Host "Resultados:" -ForegroundColor $Cyan
            Write-Host "   Total: $($script:BackendTests)" -ForegroundColor $White
            Write-Host "   Passou: $($script:BackendPassed)" -ForegroundColor $Green
            Write-Host "   Falhou: $failures" -ForegroundColor $Red
            Write-Host "   Erros: $errors" -ForegroundColor $Red
            Write-Host "   Pulou: $skipped" -ForegroundColor $Yellow
        } else {
            # Fallback: procurar por padroes de sucesso/falha
            $successCount = ($result.Output | Select-String "BUILD SUCCESS").Count
            $failureCount = ($result.Output | Select-String "BUILD FAILURE").Count
            
            if ($successCount -gt 0) {
                Write-Host "Resultados: Build executado com sucesso" -ForegroundColor $Green
                $script:BackendTests = 1
                $script:BackendPassed = 1
            } elseif ($failureCount -gt 0) {
                Write-Host "Resultados: Build falhou" -ForegroundColor $Red
                $script:BackendTests = 1
                $script:BackendPassed = 0
            } else {
                Write-Host "Nao foi possivel parsear os resultados dos testes" -ForegroundColor $Yellow
                $script:BackendTests = 1
                $script:BackendPassed = 0
            }
        }
        
        if ($Verbose) {
            Write-Host "Output completo:" -ForegroundColor $Blue
            $result.Output | ForEach-Object { Write-Host "   $_" -ForegroundColor $White }
        }
    } else {
        Write-Host "Backend: Falha na execucao dos testes" -ForegroundColor $Red
        Write-Host "   Exit Code: $($result.ExitCode)" -ForegroundColor $Red
        Write-Host "   Erro: $($result.Output)" -ForegroundColor $Red
    }
}

# Funcao para testar Frontend
function Test-Frontend {
    Write-Host ""
    Write-Host "=== TESTES DO FRONTEND (React + Vitest) ===" -ForegroundColor $Cyan
    Write-Host "===============================================" -ForegroundColor $Cyan
    
    $frontendDir = "..\LoginTester-FrontEnd"
    
    # Verificar se o diretorio existe
    if (-not (Test-Path $frontendDir)) {
        Write-Host "Diretorio do frontend nao encontrado: $frontendDir" -ForegroundColor $Red
        return
    }
    
    # Verificar se Node.js esta disponivel
    try {
        $nodeVersion = Invoke-Expression "cd '$frontendDir'; node --version" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Node.js nao esta disponivel no sistema" -ForegroundColor $Red
            Write-Host "   Instale o Node.js ou configure o PATH" -ForegroundColor $Yellow
            return
        }
        Write-Host "Node.js encontrado: $nodeVersion" -ForegroundColor $Green
    } catch {
        Write-Host "Erro ao verificar Node.js: $($_.Exception.Message)" -ForegroundColor $Red
        return
    }
    
    # Verificar se npm esta disponivel
    try {
        $npmVersion = Invoke-Expression "cd '$frontendDir'; npm --version" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "npm nao esta disponivel no sistema" -ForegroundColor $Red
            return
        }
        Write-Host "npm encontrado: $npmVersion" -ForegroundColor $Green
    } catch {
        Write-Host "Erro ao verificar npm: $($_.Exception.Message)" -ForegroundColor $Red
        return
    }
    
    # Executar testes do frontend
    $result = Invoke-TestCommand -Command "npm test -- --run --reporter=basic" -WorkingDirectory $frontendDir -TestName "Frontend Tests"
    
    # Processar resultados independente do exit code
    if ($result.ExitCode -eq 0) {
        Write-Host "Frontend: Testes executados com sucesso" -ForegroundColor $Green
    } else {
        Write-Host "Frontend: Alguns testes falharam (Exit Code: $($result.ExitCode))" -ForegroundColor $Yellow
    }
    
    # Parsear resultados do Vitest - multiplos formatos
    $testsLine = $result.Output | Select-String 'Tests\s+(\d+)\s+passed\s+\((\d+)\)'
    if (-not $testsLine) {
        # Formato alternativo
        $testsLine = $result.Output | Select-String 'Tests\s*:\s*(\d+)\s*passed,\s*(\d+)\s*total'
    }
    if (-not $testsLine) {
        # Formato com Test Files
        $testsLine = $result.Output | Select-String 'Test Files\s+(\d+)\s+passed\s+\((\d+)\)'
    }
    if (-not $testsLine) {
        # Formato compacto
        $testsLine = $result.Output | Select-String '(\d+)\s+passed\s+\((\d+)\)'
    }
    if (-not $testsLine) {
        # Formato com falhas: "1 failed | 74 passed (75)"
        $testsLine = $result.Output | Select-String '(\d+)\s+failed\s+\|\s+(\d+)\s+passed\s+\((\d+)\)'
        if ($testsLine) {
            $failed = [int]$testsLine.Matches[0].Groups[1].Value
            $passed = [int]$testsLine.Matches[0].Groups[2].Value
            $total = [int]$testsLine.Matches[0].Groups[3].Value
            $script:FrontendPassed = $passed
            $script:FrontendTests = $total
            Write-Host "Resultados parseados: $passed passaram, $failed falharam, $total total" -ForegroundColor $Cyan
        }
    }
    
    if ($testsLine -and -not $script:FrontendTests) {
        $script:FrontendPassed = [int]$testsLine.Matches[0].Groups[1].Value
        $script:FrontendTests = [int]$testsLine.Matches[0].Groups[2].Value
    }
    
    if (-not $script:FrontendTests) {
        # Fallback: procurar por padroes de sucesso/falha
        $successCount = ($result.Output | Select-String "PASS|passed").Count
        $failureCount = ($result.Output | Select-String "FAIL|failed").Count
        
        if ($successCount -gt 0 -and $failureCount -eq 0) {
            Write-Host "Resultados: Todos os testes passaram" -ForegroundColor $Green
            $script:FrontendTests = $successCount
            $script:FrontendPassed = $successCount
        } elseif ($successCount -gt 0) {
            Write-Host "Resultados: Alguns testes falharam" -ForegroundColor $Yellow
            $script:FrontendTests = $successCount + $failureCount
            $script:FrontendPassed = $successCount
        } elseif ($result.Success) {
            Write-Host "Resultados: Testes executados com sucesso (sem contagem precisa)" -ForegroundColor $Green
            $script:FrontendTests = 1
            $script:FrontendPassed = 1
        } else {
            Write-Host "Resultados: Testes falharam" -ForegroundColor $Red
            $script:FrontendTests = 1
            $script:FrontendPassed = 0
        }
    }

    if ($script:FrontendTests -gt 0) {
        Write-Host "Resultados:" -ForegroundColor $Cyan
        Write-Host "   Total: $($script:FrontendTests)" -ForegroundColor $White
        Write-Host "   Passou: $($script:FrontendPassed)" -ForegroundColor $Green
        Write-Host "   Falhou: $($script:FrontendTests - $script:FrontendPassed)" -ForegroundColor $Red
    } else {
        Write-Host "Nao foi possivel parsear os resultados dos testes (Total=0)" -ForegroundColor $Yellow
    }
    
    if ($Verbose) {
        Write-Host "Output completo:" -ForegroundColor $Blue
        $result.Output | ForEach-Object { Write-Host "   $_" -ForegroundColor $White }
    }
}

# Funcao para testar Integracao
function Test-Integration {
    Write-Host ""
    Write-Host "=== TESTES DE INTEGRACAO (API + Sistema) ===" -ForegroundColor $Cyan
    Write-Host "===============================================" -ForegroundColor $Cyan
    
    $script:IntegrationTests = 5
    $script:IntegrationPassed = 0
    
    # TESTE 1: Verificar se API esta respondendo
    Write-Host "Testando se API esta respondendo..." -ForegroundColor $Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/swagger-ui.html" -Method GET -UseBasicParsing -TimeoutSec 5
        Write-Host "API esta respondendo" -ForegroundColor $Green
        $script:IntegrationPassed++
    } catch {
        Write-Host "API nao esta respondendo: $($_.Exception.Message)" -ForegroundColor $Red
    }
    
    # TESTE 2: Registro de usuario
    Write-Host "Testando registro de usuario..." -ForegroundColor $Yellow
    $testUserEmail = $null
    try {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $uniqueEmail = "test$timestamp@logintester.com"
        $testUserEmail = $uniqueEmail
        
        $registerBody = @{
            name = "Test User"
            email = $uniqueEmail
            password = "Test123!"
            confirmPassword = "Test123!"
        } | ConvertTo-Json

        $registerResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/auth/register" -Method POST -Body $registerBody -ContentType "application/json" -UseBasicParsing -TimeoutSec 10
        
        if ($registerResponse.StatusCode -eq 200 -or $registerResponse.StatusCode -eq 201) {
            Write-Host "Registro de usuario OK" -ForegroundColor $Green
            $script:IntegrationPassed++
            
            # LIMPEZA: Remover usuario de teste criado
            Write-Host "Limpando usuario de teste criado..." -ForegroundColor $Yellow
            try {
                # Tentar limpar via script SQL automatico
                $cleanupScript = "..\LoginTester-DB\cleanup-test-users-auto.ps1"
                if (Test-Path $cleanupScript) {
                    & $cleanupScript | Out-Null
                    Write-Host "Usuario de teste removido com sucesso" -ForegroundColor $Green
                } else {
                    Write-Host "Aviso: Script de limpeza automatica nao encontrado" -ForegroundColor $Yellow
                    Write-Host "   Usuario de teste '$uniqueEmail' permanecera no banco" -ForegroundColor $Yellow
                    Write-Host "   Execute manualmente: cd LoginTester-DB; .\cleanup-test-users.ps1 -DryRun:`$false" -ForegroundColor $Yellow
                }
            } catch {
                Write-Host "Aviso: Nao foi possivel fazer limpeza automatica do usuario de teste" -ForegroundColor $Yellow
                Write-Host "   Erro: $($_.Exception.Message)" -ForegroundColor $Red
            }
        } else {
            Write-Host "Registro de usuario falhou - Status: $($registerResponse.StatusCode)" -ForegroundColor $Red
        }
    } catch {
        Write-Host "Registro de usuario falhou: $($_.Exception.Message)" -ForegroundColor $Red
        if ($_.Exception.Response) {
            Write-Host "   Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor $Red
        }
    }
    
    # TESTE 3: Login de usuario
    Write-Host "Testando login de usuario..." -ForegroundColor $Yellow
    try {
        $loginBody = @{
            email = "user@mail.com"
            password = "user123"
        } | ConvertTo-Json

        $loginResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/auth/login" -Method POST -Body $loginBody -ContentType "application/json" -UseBasicParsing -TimeoutSec 10
        
        if ($loginResponse.StatusCode -eq 200 -and ($loginResponse.Content -like "*Login realizado com sucesso*" -or $loginResponse.Content -like "*user*")) {
            Write-Host "Login de usuario OK" -ForegroundColor $Green
            $script:IntegrationPassed++
        } else {
            Write-Host "Login de usuario falhou - Status: $($loginResponse.StatusCode)" -ForegroundColor $Red
        }
    } catch {
        Write-Host "Login de usuario falhou: $($_.Exception.Message)" -ForegroundColor $Red
        if ($_.Exception.Response) {
            Write-Host "   Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor $Red
        }
    }
    
    # TESTE 4: Login de admin
    Write-Host "Testando login de admin..." -ForegroundColor $Yellow
    try {
        $adminLoginBody = @{
            email = "admin@mail.com"
            password = "admin123"
        } | ConvertTo-Json

        $adminLoginResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/auth/login" -Method POST -Body $adminLoginBody -ContentType "application/json" -UseBasicParsing -SessionVariable "adminSession" -TimeoutSec 10
        
        if ($adminLoginResponse.StatusCode -eq 200 -and ($adminLoginResponse.Content -like "*Login realizado com sucesso*" -or $adminLoginResponse.Content -like "*admin*")) {
            Write-Host "Login de admin OK" -ForegroundColor $Green
            $script:IntegrationPassed++
        } else {
            Write-Host "Login de admin falhou - Status: $($adminLoginResponse.StatusCode)" -ForegroundColor $Red
        }
    } catch {
        Write-Host "Login de admin falhou: $($_.Exception.Message)" -ForegroundColor $Red
        if ($_.Exception.Response) {
            Write-Host "   Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor $Red
        }
    }
    
    # TESTE 5: API de seguranca
    Write-Host "Testando API de seguranca..." -ForegroundColor $Yellow
    try {
        $securityResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/security/dashboard" -Method GET -WebSession $adminSession -UseBasicParsing -TimeoutSec 10
        
        if ($securityResponse.StatusCode -eq 200 -and ($securityResponse.Content -like "*totalLoginsToday*" -or $securityResponse.Content -like "*security*")) {
            Write-Host "API de seguranca OK" -ForegroundColor $Green
            $script:IntegrationPassed++
        } else {
            Write-Host "API de seguranca falhou - Status: $($securityResponse.StatusCode)" -ForegroundColor $Red
        }
    } catch {
        Write-Host "API de seguranca falhou: $($_.Exception.Message)" -ForegroundColor $Red
        if ($_.Exception.Response) {
            Write-Host "   Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor $Red
        }
    }
}

# Funcao para mostrar resumo final
function Show-FinalReport {
    Write-Host ""
    Write-Host "=== RELATORIO FINAL DOS TESTES ===" -ForegroundColor $Cyan
    Write-Host "=====================================" -ForegroundColor $Cyan
    Write-Host ""
    
    $script:TotalTests = $script:BackendTests + $script:FrontendTests + $script:IntegrationTests
    $script:TotalPassed = $script:BackendPassed + $script:FrontendPassed + $script:IntegrationPassed
    
    Write-Host "Backend (Spring Boot + Maven):" -ForegroundColor $Yellow
    Write-Host "   Testes: $($script:BackendPassed)/$($script:BackendTests)" -ForegroundColor $White
    
    Write-Host "Frontend (React + Vitest):" -ForegroundColor $Yellow
    Write-Host "   Testes: $($script:FrontendPassed)/$($script:FrontendTests)" -ForegroundColor $White
    
    Write-Host "Integracao (API + Sistema):" -ForegroundColor $Yellow
    Write-Host "   Testes: $($script:IntegrationPassed)/$($script:IntegrationTests)" -ForegroundColor $White
    
    Write-Host ""
    Write-Host "TOTAL GERAL:" -ForegroundColor $Cyan
    Write-Host "   Testes: $script:TotalPassed/$script:TotalTests" -ForegroundColor $White
    
    $successRate = if ($script:TotalTests -gt 0) { [math]::Round(($script:TotalPassed / $script:TotalTests) * 100, 2) } else { 0 }
    Write-Host "   Taxa de Sucesso: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { $Green } elseif ($successRate -ge 70) { $Yellow } else { $Red })
    
    Write-Host ""
    if ($script:TotalPassed -eq $script:TotalTests -and $script:TotalTests -gt 0) {
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
    Write-Host "  - Execute com -Verbose para ver output completo" -ForegroundColor $White
    Write-Host "  - Execute '.\manage.ps1 logs backend' para logs do backend" -ForegroundColor $White
    Write-Host "  - Execute '.\manage.ps1 logs frontend' para logs do frontend" -ForegroundColor $White
    Write-Host "  - Acesse http://localhost:8080/swagger-ui.html para testar APIs" -ForegroundColor $White
}

# Funcao principal
function Main {
    Write-Host ""
    Write-Host "LoginTester - Executando Todos os Testes" -ForegroundColor $Cyan
    Write-Host "===========================================" -ForegroundColor $Cyan
    Write-Host ""
    
    # Salvar diretorio atual para retornar ao final
    $originalDirectory = Get-Location
    
    try {
        # Verificar se o sistema esta rodando
        Write-Host "Verificando se o sistema esta rodando..." -ForegroundColor $Yellow
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8080/swagger-ui.html" -Method GET -UseBasicParsing -TimeoutSec 5
            Write-Host "Sistema esta rodando!" -ForegroundColor $Green
        } catch {
            Write-Host "Sistema nao esta rodando!" -ForegroundColor $Red
            Write-Host "   Tentando iniciar automaticamente..." -ForegroundColor $Yellow
            
            try {
                & .\manage.ps1 start | Out-Null
                Write-Host "Sistema iniciado automaticamente!" -ForegroundColor $Green
                
                # Aguardar sistema ficar pronto
                Write-Host "Aguardando sistema ficar pronto..." -ForegroundColor $Yellow
                $maxRetries = 30
                for ($i = 1; $i -le $maxRetries; $i++) {
                    Start-Sleep -Milliseconds 2000
                    try {
                        $response = Invoke-WebRequest -Uri "http://localhost:8080/swagger-ui.html" -Method GET -UseBasicParsing -TimeoutSec 3
                        Write-Host "Sistema pronto!" -ForegroundColor $Green
                        break
                    } catch {
                        if ($i -eq $maxRetries) {
                            Write-Host "Timeout aguardando sistema ficar pronto." -ForegroundColor $Red
                            Write-Host "   Execute '.\manage.ps1 start' manualmente e tente novamente" -ForegroundColor $Yellow
                            return
                        }
                    }
                }
            } catch {
                Write-Host "Falha ao iniciar sistema automaticamente: $($_.Exception.Message)" -ForegroundColor $Red
                Write-Host "   Execute '.\manage.ps1 start' primeiro para iniciar o sistema" -ForegroundColor $Yellow
                return
            }
        }
        
        Write-Host ""
        
        # Executar testes conforme parametros
        if (-not $SkipBackend) {
            Test-Backend
        } else {
            Write-Host "Pulando testes do Backend" -ForegroundColor $Yellow
        }
        
        if (-not $SkipFrontend) {
            Test-Frontend
        } else {
            Write-Host "Pulando testes do Frontend" -ForegroundColor $Yellow
        }
        
        if (-not $SkipIntegration) {
            Test-Integration
        } else {
            Write-Host "Pulando testes de Integracao" -ForegroundColor $Yellow
        }
        
        # Mostrar relatorio final
        Show-FinalReport
        
    } finally {
        # Sempre retornar para o diretorio original (pasta Docker)
        Write-Host ""
        Write-Host "Retornando para diretorio Docker..." -ForegroundColor $Blue
        Set-Location $originalDirectory
        Write-Host "Diretorio atual: $(Get-Location)" -ForegroundColor $White
    }
}

# Executar funcao principal
Main
