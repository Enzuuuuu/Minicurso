# Convites n8n — formulário que coleta e-mails e envia convites

Este é o fluxo de convites, não o de Central de Atendimento.

## Onde a lógica está no projeto original

- `C:\Users\Francisco\Desktop\API_N8N\convites.template.json` — template completo do workflow.
- `C:\Users\Francisco\Desktop\API_N8N\create-convites.ps1` — cria e ativa o workflow no n8n pela CLI.
- `C:\Users\Francisco\Desktop\API_N8N\test-convites-workflow.js` — testes do fluxo.
- `.env` / `.env.example` na raiz do projeto — configuração local (não publicar).

## Fluxo do workflow

1. **`Formulário de convites`** (`n8n-nodes-base.formTrigger`, `typeVersion: 2.2`)
   - Título: `Convitar usuários no n8n`.
   - Descrição: `Informe um ou mais e-mails, um por linha. O convite é enviado pela API do n8n.`
   - Campo `emails` (textarea, obrigatório): aceita vários e-mails separados por espaço, vírgula, ponto e vírgula ou quebra de linha.
   - Campo `perfil` (dropdown, obrigatório): `global:member` ou `global:admin`, padrão `global:member`.
   - Botão: `Enviar convites`; `ignoreBots: true`; `responseMode: responseNode`.
   - Caminho padrão: `convites-n8n` → `/form/convites-n8n`.

2. **`Normalizar e-mails`** (`Set`)
   - Divide `emails` com `/[\s,;]+/`, faz `trim().toLowerCase()`, filtra com regex de e-mail e remove duplicatas com `Set`.
   - Resultado: array `[{ "email": "...", "role": "global:member" }]`.

3. **`Tem e-mails válidos?`** (`If`, `array notEmpty`)
   - Vazio → `Montar aviso` → `Responder formulário`.
   - Não vazio → `Convidar usuários`.

4. **`Convidar usuários`** (`HTTP Request`, `typeVersion: 4.2`)
   - `POST {{N8N_BASE_URL}}/api/v1/users`
   - Corpo JSON: o array normalizado.
   - Cabeçalho: `Idempotency-Key: {{ 'convite-' + $execution.id }}`.
   - Autenticação: `genericCredentialType` + `httpHeaderAuth`, com `X-N8N-API-KEY` (chave com escopo `user:create`).
   - `onError=continueErrorOutput`; retry 3 vezes com 5 s entre tentativas; resposta `json` com `fullResponse=true`.

5. **`Montar resumo`** (`Set`)
   - Conta `total`, `enviados` (`body[].user.emailSent`) e `falhas` (`body[].error`).
   - Monta o HTML devolvido ao formulário com `OK <email>` ou `FALHA <email>: <erro>`.

6. **`Existem links pendentes?`** (`If`)
   - Filtra `body[].user.inviteAcceptUrl`.
   - Com links → **`Enviar link de convite`** (`n8n-nodes-base.gmail`, `typeVersion: 2.1`):
     - `sendTo`: e-mails com link, separados por vírgula.
     - `subject`: `Seu convite para o n8n`.
     - `message`: `Use os links abaixo para aceitar seu convite no n8n:` + `email: inviteAcceptUrl`, um por linha com `<br>`.
     - Credencial: Gmail OAuth2.

7. **`Responder formulário`** (`respondToWebhook`) devolve `$json.mensagem` com status `200`.
   - Falha da API vai para `Montar erro da API` e também responde ao formulário.

## Registro rápido no n8n

- Credencial 1: **Header Auth** com `name = X-N8N-API-KEY` e `value = <sua API key com user:create>`.
- Credencial 2: **Gmail OAuth2** para enviar os links de aceite.
- Variáveis usadas pelo gerador: `N8N_URL`, `N8N_API_KEY`, `N8N_WORKFLOW_NAME_CONVITES`, `N8N_CONVITES_FORM_PATH`.
- Gerar/ativar a partir da raiz do projeto:

```powershell
powershell -ExecutionPolicy Bypass -File .\create-convites.ps1 -BaseUrl https://seu-n8n -FormPath convites-n8n -Name "Convites n8n"
```

- Abrir o formulário: `https://seu-n8n/form/convites-n8n` (ou `http://localhost:5678/form/convites-n8n`).
- Teste rápido: informar `ana@empresa.com; bruno@empresa.com`, perfil `global:member` e conferir o resumo na tela e o e-mail com o link de aceite.

> Não publique API keys, e-mails reais nem IDs de credencial neste repositório.
