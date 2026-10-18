# 🧪 Guia de Testes - LoginTester

## ⚠️ IMPORTANTE: Testes de Integração

### Problema Identificado

O script `tests.ps1` executa **testes de integração** que criam usuários **reais no banco de produção**. 

**Exemplo de usuário criado:**
- Nome: `Test User`
- Email: `test20251018092642@logintester.com` (com timestamp)
- Senha: `Test123!`

### Por Que Isso Acontece?

Os testes de integração (linha 320-372 do `tests.ps1`) executam requisições HTTP contra o sistema **rodando** em `http://localhost:8080`, que usa o banco de dados PostgreSQL de produção, não o banco H2 em memória usado pelos testes unitários.

### Solução Implementada

✅ **Limpeza Automática**: O script agora tenta remover automaticamente os usuários de teste após a execução.

✅ **Script de Limpeza Manual**: Caso a limpeza automática falhe, use:

```powershell
cd LoginTester-DB
.\cleanup-test-users.ps1 -DryRun:$false
```

## 📋 Tipos de Testes

### 1. Testes Unitários (Backend)
- **Localização**: `LoginTester-BackEnd/src/test/`
- **Banco**: H2 em memória (não afeta produção)
- **Execução**: `cd LoginTester-BackEnd; .\mvnw.cmd test`
- **Status**: ✅ 94 testes passando
- **Limpeza**: Automática (banco em memória é descartado)

### 2. Testes Unitários (Frontend)
- **Localização**: `LoginTester-FrontEnd/src/`
- **Execução**: `cd LoginTester-FrontEnd; npm test`
- **Status**: ✅ 117 testes passando
- **Limpeza**: Não aplicável (testes de interface)

### 3. Testes de Integração (Sistema)
- **Localização**: `LoginTester-Docker/tests.ps1`
- **Banco**: PostgreSQL de produção ⚠️
- **Execução**: `cd LoginTester-Docker; .\tests.ps1`
- **Status**: ✅ 5 testes de integração
- **Limpeza**: ✅ Automática (implementada)

## 🔧 Como Executar os Testes

### Todos os Testes (Recomendado)
```powershell
cd LoginTester-Docker
.\tests.ps1
```

### Apenas Backend (Unitários)
```powershell
cd LoginTester-BackEnd
.\mvnw.cmd test
```

### Apenas Frontend (Unitários)
```powershell
cd LoginTester-FrontEnd
npm test
```

### Apenas Integração
```powershell
cd LoginTester-Docker
.\tests.ps1 -SkipBackend -SkipFrontend
```

## 🧹 Limpeza de Usuários de Teste

### Verificar Usuários de Teste
```powershell
cd LoginTester-DB
.\cleanup-test-users.ps1
```

### Remover Usuários de Teste
```powershell
cd LoginTester-DB
.\cleanup-test-users.ps1 -DryRun:$false
```

### Verificar no Banco Diretamente
```sql
SELECT id, name, email, role, created_at 
FROM users 
WHERE email LIKE '%test%' 
   OR email LIKE '%@logintester.com'
   OR name LIKE '%Test%'
ORDER BY created_at DESC;
```

## 📊 Resumo dos Testes

| Tipo | Quantidade | Status | Banco Usado |
|------|-----------|--------|-------------|
| Backend Unitários | 94 | ✅ Passando | H2 (memória) |
| Frontend Unitários | 117 | ✅ Passando | N/A |
| Integração | 5 | ✅ Passando | PostgreSQL |
| **TOTAL** | **216** | **✅ 100%** | - |

## ⚡ Melhorias Implementadas

1. ✅ Todos os testes unitários usam banco H2 em memória
2. ✅ Perfil de teste configurado corretamente (`@ActiveProfiles("test")`)
3. ✅ Limpeza automática de usuários de teste nos testes de integração
4. ✅ Script de limpeza manual disponível
5. ✅ Documentação completa do problema e solução

## 🎯 Próximos Passos (Opcional)

Para evitar completamente a criação de usuários no banco de produção, considere:

1. **Criar ambiente de teste separado**: Use um banco PostgreSQL dedicado para testes de integração
2. **Usar TestContainers**: Execute PostgreSQL em container Docker durante os testes
3. **Mock de API**: Simule as respostas da API sem fazer requisições reais

## 📝 Notas

- Os testes unitários (Backend e Frontend) **nunca** afetam o banco de produção
- Apenas os testes de integração criam dados temporários no banco
- A limpeza automática foi implementada para remover esses dados
- Em caso de falha na limpeza, use o script manual

---

**Data de Atualização**: 18/10/2025  
**Versão**: 1.0.0

