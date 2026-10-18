# LoginTester Docker - Configuração Unificada

## 📖 Resumo

Este repositório contém a configuração Docker unificada para o projeto LoginTester. O sistema funciona tanto localmente (HTTP) quanto externamente (HTTPS via ngrok) com uma única configuração.

## 🎯 Objetivo

Fornecer uma configuração única que funcione em qualquer ambiente:
- **Local**: HTTP via localhost
- **Externo**: HTTPS via ngrok (quando necessário)
- **Desenvolvimento**: Com dados de teste
- **Produção**: Com configurações otimizadas

## ⚙️ Requisitos Funcionais

### RF-001: Orquestração de Containers
- ✅ Executa todos os serviços (frontend, backend, database) em containers isolados
- ✅ Gerencia a comunicação entre serviços via rede Docker
- ✅ Garante a ordem de inicialização correta (database → backend → frontend → nginx)

### RF-002: Proxy Reverso com Nginx
- ✅ Roteia requisições para os serviços apropriados
- ✅ Serve o frontend na porta 80
- ✅ Direciona chamadas `/api/*` para o backend
- ✅ Fornece acesso ao Swagger UI em `/swagger`

### RF-003: Gestão de Ambientes
- ✅ Suporta desenvolvimento isolado por serviço
- ✅ Suporta execução completa integrada
- ✅ Permite override de configurações por ambiente

## 🔧 Requisitos Não-Funcionais

### RNF-001: Segurança
- ✅ Variáveis sensíveis são gerenciadas via .env
- ✅ .env não é versionado no Git
- ✅ Comunicação entre containers é via rede interna

### RNF-002: Desenvolvimento
- ✅ Cada desenvolvedor pode testar seu serviço isoladamente
- ✅ Permite hot-reload em desenvolvimento
- ✅ Configurações de dev não afetam produção

### RNF-003: Performance
- ✅ Containers iniciam em menos de 30 segundos
- ✅ Nginx serve como cache reverso
- ✅ Conexões de banco usam pooling

## 📊 Regras de Negócio

### RN-001: Gestão de Configurações
- Configurações de produção têm prioridade sobre desenvolvimento
- Cada serviço mantém seu .env específico para configurações de aplicação
- O docker-compose centraliza configurações de infraestrutura

### RN-002: Comunicação entre Serviços
- Frontend comunica-se apenas com Nginx
- Backend comunica-se com Database via rede Docker interna
- Nginx atua como único ponto de entrada externo

### RN-003: Ambiente de Desenvolvimento
- Desenvolvedores podem subir apenas seu serviço + dependências
- Database é acessível externamente em desenvolvimento
- Hot-reload funciona em modo desenvolvimento

## 🗂️ Estrutura de Serviços

```
Nginx (Proxy) → Frontend (React)
              → Backend (Spring Boot) → Database (PostgreSQL)
              → Swagger UI
```

## 🔗 Dependências entre Serviços
1. Database ← Backend ← Frontend ← Nginx
2. Qualquer serviço pode ser executado isoladamente com dependências mockadas
3. Em desenvolvimento completo, todos os serviços estão sincronizados

## 🚀 Como Usar

### 1. Inicialização Rápida

#### Windows (PowerShell)
```powershell
# Na raiz do projeto
.\LoginTester-Docker\manage.ps1 start

# Para limpar volumes antigos
.\LoginTester-Docker\manage.ps1 clean
```

#### Linux/Mac (Bash)
```bash
# Na raiz do projeto
cd LoginTester-Docker

# Iniciar todos os serviços
docker-compose up --build -d

# Para limpar volumes antigos
docker-compose down -v
```

### 2. Inicialização Manual

```bash
# Navegar para a pasta Docker
cd LoginTester-Docker

# Criar arquivo .env (se não existir)
cp env.example .env

# Iniciar todos os serviços
docker-compose up --build -d

# Ver logs
docker-compose logs -f
```

### 3. Configuração do email (recuperação de senha e verificação)

Para que os emails de **recuperação de senha** e **verificação de email** sejam enviados, configure uma conta Gmail (ex.: `ktakeapps@gmail.com`):

1. **Arquivo `.env`:** use `env.example` como base (`cp env.example .env`).
2. **Variáveis obrigatórias:**
   - `GMAIL_USERNAME` – email completo (ex.: `ktakeapps@gmail.com`).
   - `GMAIL_APP_PASSWORD` – [senha de app do Gmail](https://support.google.com/accounts/answer/185833) (Conta Google → Segurança → Verificação em 2 etapas → Senhas de app). Não use a senha normal da conta.
   - `EMAIL_FROM` – remetente exibido nos emails (geralmente o mesmo que `GMAIL_USERNAME`).
   - `FRONTEND_URL` – URL do frontend (para links nos emails; em local: `http://localhost:3000`).
3. Reinicie os containers após alterar o `.env` (ex.: `.\manage.ps1 restart`).

Sem essas variáveis, o backend sobe normalmente, mas o envio de email (esqueci senha, códigos de verificação) falhará.

### 4. Comandos Úteis

```bash
# Ver status dos serviços
docker-compose ps

# Parar todos os serviços
docker-compose down

# Reiniciar um serviço específico
docker-compose restart backend

# Limpar tudo (incluindo volumes)
docker-compose down -v

# Executar comandos dentro de um container
docker-compose exec backend bash
docker-compose exec database psql -U logintester_admin -d logintester_db
```

## 🌐 Acessos

Após a inicialização, os serviços estarão disponíveis em:

- **Frontend (principal)**: http://localhost
- **Frontend (porta)**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **Swagger UI**: http://localhost:8080/swagger-ui.html
- **Database**: localhost:5432

### 🔒 Para Acesso Externo (HTTPS)

O sistema detecta automaticamente se há um domínio ngrok configurado no arquivo `.env`:

1. **Configure o domínio** no arquivo `.env`:
   ```bash
   NGROK_DOMAIN=https://seu-dominio.ngrok-free.dev
   ```

2. **O sistema mostrará automaticamente** os links externos quando iniciar:
   - Frontend: `https://seu-dominio.ngrok-free.dev`
   - Backend: `https://seu-dominio.ngrok-free.dev/api`
   - Swagger: `https://seu-dominio.ngrok-free.dev/api/swagger-ui.html`

3. **Alternativa**: Execute `ngrok http localhost` para gerar um novo domínio

## 🚀 Scripts de Gerenciamento

### Windows (PowerShell)
```powershell
# Iniciar todos os serviços (inclui ngrok automaticamente)
.\manage.ps1 start

# Parar todos os serviços
.\manage.ps1 stop

# Reiniciar todos os serviços
.\manage.ps1 restart

# Ver logs de todos os serviços
.\manage.ps1 logs

# Ver logs de um serviço específico
.\manage.ps1 logs backend

# Ver status dos containers
.\manage.ps1 status

# Limpeza completa (remove containers e volumes)
.\manage.ps1 clean

# Acessar banco de dados
.\manage.ps1 db

# Gerenciar ngrok
.\manage.ps1 ngrok start    # Inicia ngrok
.\manage.ps1 ngrok stop     # Para ngrok
.\manage.ps1 ngrok status  # Status do ngrok

# Mostrar ajuda
.\manage.ps1 help
```

### Linux/Mac (Bash)
```bash
# Navegar para o diretório
cd LoginTester-Docker

# Tornar script executável
chmod +x manage.sh

# Iniciar em modo desenvolvimento (com dados de teste)
./manage.sh start dev

# Iniciar em modo produção (banco limpo)
./manage.sh start prod

# Parar serviços
./manage.sh stop dev

# Ver logs
./manage.sh logs dev

# Limpeza completa (CUIDADO!)
./manage.sh clean dev

# Acessar banco de dados
./manage.sh db dev

# Executar query SQL
./manage.sh db-query "SELECT * FROM users;"
```

## 🔐 Credenciais de Teste

O sistema vem com usuários pré-configurados para testes:

| Email | Senha | Role | Descrição |
|-------|-------|------|-----------|
| `admin@mail.com` | `admin123` | ADMIN | Administrador completo |
| `user@mail.com` | `user123` | USER | Usuário comum |
| `unverified@mail.com` | `unverified123` | UNVERIFIED | Usuário não verificado |
| `gkenzo@gmail.com` | `kenzo123` | USER | Usuário de teste adicional |

## 📁 Estrutura de Arquivos

```
LoginTester-Docker/
├── docker-compose.yml              # Configuração unificada
├── env.example                     # Exemplo de variáveis de ambiente
├── manage.ps1                      # Script de gerenciamento
├── nginx/
│   └── nginx-simple.conf           # Configuração do Nginx
└── scripts/
    └── README.md                    # Documentação dos scripts
```

## ⚙️ Configuração

### Variáveis de Ambiente

As principais variáveis podem ser configuradas no arquivo `.env`:

```bash
# Database Configuration
POSTGRES_USER=logintester_admin
POSTGRES_PASSWORD=logintester_password
POSTGRES_DB=logintester_db

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRATION=86400000

# Frontend Configuration
VITE_API_URL=/api
VITE_APP_NAME=LoginTester
VITE_ENVIRONMENT=unified

# Ngrok Configuration (para acesso externo)
NGROK_DOMAIN=https://seu-dominio.ngrok-free.dev

# Port Configuration
NGINX_PORT=80
FRONTEND_PORT=3000
BACKEND_PORT=8080
```

### Variáveis de ambiente para produção (Backend)

Para deploy em **produção com HTTPS**, configure no `.env`:

| Variável | Descrição | Exemplo (produção) |
|----------|-----------|---------------------|
| `APP_COOKIE_SECURE` | Cookie de logout enviado apenas em HTTPS | `true` |
| `APP_SECURITY_HSTS_ENABLED` | HSTS (Strict-Transport-Security) | `true` |
| `SPRING_PROFILES_ACTIVE` | Perfil Spring: `dev` (show-sql no log) ou `prod` | `prod` |
| `app.password.common-passwords` | Lista de senhas fracas (vírgula); opcional | (já em application.properties) |

O backend lê essas variáveis via `docker-compose.yml` (serviço `backend`). Em desenvolvimento use `APP_COOKIE_SECURE=false`, `APP_SECURITY_HSTS_ENABLED=false` e `SPRING_PROFILES_ACTIVE=dev`.

Opcional: para carregar a lista de senhas fracas de um arquivo (um por linha), defina no `.env` do backend ou em `application.properties` a propriedade `app.password.common-passwords-file` com o caminho do arquivo. Se estiver definida, ela tem prioridade sobre `app.password.common-passwords`.

### Detecção Automática de Links Externos

O sistema detecta automaticamente se há um domínio ngrok configurado e mostra os links externos quando:
- Inicia o sistema (`.\manage.ps1 start`)
- Verifica o status (`.\manage.ps1 status`)

### 🤖 Automação do Ngrok

O sistema agora **inicia o ngrok automaticamente** quando você executa `.\manage.ps1 start`:

- ✅ **Detecção automática**: Verifica se ngrok está rodando
- ✅ **Inicialização automática**: Inicia ngrok se não estiver rodando
- ✅ **Atualização do .env**: Atualiza automaticamente o domínio no arquivo `.env`
- ✅ **Gerenciamento manual**: Comandos específicos para controlar o ngrok

#### Comandos de Gerenciamento do Ngrok:
```powershell
# Ver status do ngrok
.\manage.ps1 ngrok status

# Iniciar ngrok manualmente
.\manage.ps1 ngrok start

# Parar ngrok
.\manage.ps1 ngrok stop

# Ver ajuda do ngrok
.\manage.ps1 ngrok
```

## 🗄️ Scripts de Banco de Dados

## 🔧 Troubleshooting

### Problemas Comuns

#### 1. Porta já em uso
```bash
# Verificar processos usando as portas
netstat -ano | findstr :80
netstat -ano | findstr :8080
netstat -ano | findstr :5432

# Parar serviços conflitantes ou usar portas diferentes
```

#### 2. Containers não iniciam
```bash
# Verificar logs
docker-compose logs

# Limpar e recriar
docker-compose down -v
docker-compose up --build -d
```

#### 3. Banco de dados não conecta
```bash
# Verificar se o container está rodando
docker-compose ps

# Verificar logs do banco
docker-compose logs database

# Testar conexão manual
docker-compose exec database psql -U logintester_admin -d logintester_db
```

#### 4. CORS errors no frontend
- O sistema aceita qualquer origem automaticamente
- Se persistir, verifique se o backend está rodando na porta 8080
- Para acesso externo, use ngrok: `ngrok http localhost`

### Comandos Úteis

```bash
# Ver status de todos os containers
docker-compose ps

# Ver logs em tempo real
docker-compose logs -f

# Executar comandos dentro de containers
docker-compose exec backend bash
docker-compose exec database psql -U logintester_admin -d logintester_db

# Limpeza completa
docker-compose down -v
docker system prune -f
```

## 📝 Notas Importantes

- **Configuração única**: Funciona tanto localmente quanto externamente
- **Dados de teste**: Sempre disponíveis para facilitar desenvolvimento
- **CORS flexível**: Aceita qualquer origem automaticamente
- **Acesso externo**: Use ngrok quando necessário para HTTPS
- **Banco persistente**: Dados mantidos entre reinicializações