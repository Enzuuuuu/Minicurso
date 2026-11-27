# Convites n8n — formulário de e-mail que envia convite

Este é o fluxo de convites, não o de Central de Atendimento.

## Estado atual

- Workflow ativo: **`Convites n8n (formulário simples)`** — id `2YJ08f0XYGUwxrr3`.
- Webhook: `http://localhost:5678/webhook/convites-n8n`.
- Formulário no slide 12 de `index.html`: campo único `email`, enviado como POST JSON `{ "email": "..." }`.
- Perfil do convite fixo em `global:member`.
- Credenciais usadas no n8n:
  - **Header Auth** `n8n API Key (convites)` com `X-N8N-API-KEY` (chave com escopo `user:create`).
  - **Gmail OAuth2** `Gmail account` para enviar o link de aceite.
- No GitHub Pages, substitua `data-webhook` do formulário pela URL pública do seu n8n; `localhost:5678` só funciona no mesmo computador.

## Onde a lógica está no projeto original

- `C:\Users\Francisco\Desktop\API_N8N\convites.template.json` — template completo com formulário de `emails` e `perfil`.
- `C:\Users\Francisco\Desktop\API_N8N\create-convites.ps1` — cria e ativa o workflow no n8n pela CLI.
- `C:\Users\Francisco\Desktop\API_N8N\test-convites-workflow.js` — testes do fluxo.
- `.env` / `.env.example` na raiz do projeto — configuração local (não publicar).

## Fluxo do workflow ativo

1. **`Webhook de convites`** (`n8n-nodes-base.webhook`, `typeVersion: 2`)
   - `POST` em `/webhook/convites-n8n`; `responseMode: responseNode`.
   - Corpo esperado: `{ "email": "voce@empresa.com" }`.

2. **`Normalizar e-mails`** (`Set`)
   - Lê `$json.body.email`, divide por espaço/vírgula/ponto e vírgula, faz `trim().toLowerCase()`, filtra com regex de e-mail e remove duplicatas com `Set`.
   - Resultado: `[{ "email": "...", "role": "global:member" }]`.

3. **`Tem e-mails válidos?`** (`If`, `array notEmpty`)
   - Vazio → `Montar aviso` → `Responder formulário`.
   - Não vazio → `Convidar usuários`.

4. **`Convidar usuários`** (`HTTP Request`, `typeVersion: 4.2`)
   - `POST {{N8N_BASE_URL}}/api/v1/users`.
   - Corpo JSON: o array normalizado.
   - Cabeçalho: `Idempotency-Key: {{ 'convite-' + $execution.id }}`.
   - Autenticação: `genericCredentialType` + `httpHeaderAuth`, com `X-N8N-API-KEY`.
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

7. **`Responder formulário`** (`respondToWebhook`) devolve `$json.mensagem` com status `200`.
   - Falha da API vai para `Montar erro da API` e também responde ao formulário.

## Registro rápido no n8n

- O gerador `create-convites.ps1` cria a variante com `Formulário de convites`, campos `emails` e `perfil` e caminho `/form/convites-n8n`. O workflow ativo no deck é a variante com Webhook `POST` e campo único `email`.
- Variáveis usadas pelo gerador: `N8N_URL`, `N8N_API_KEY`, `N8N_WORKFLOW_NAME_CONVITES`, `N8N_CONVITES_FORM_PATH`.
- Gerar/ativar a variante do template a partir da raiz do projeto:

```powershell
powershell -ExecutionPolicy Bypass -File .\create-convites.ps1 -BaseUrl https://seu-n8n -FormPath convites-n8n -Name "Convites n8n"
```

- Teste sem criar convite nem enviar e-mail:

```powershell
Invoke-RestMethod -Method Post -Uri "http://localhost:5678/webhook/convites-n8n" -ContentType "application/json" -Body '{"email":"invalido"}'
```

- Teste real: enviar `{ "email": "ana@empresa.com" }` e conferir o resumo na tela e o e-mail com o link de aceite.

> Não publique API keys, e-mails reais nem IDs de credencial neste repositório.
