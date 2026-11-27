# Instruções de uso

Este guia explica como subir o n8n com uma URL pública temporária em **uma única execução**, usando o script `iniciar-n8n.ps1`.

## Pré-requisitos

- Windows com PowerShell
- Docker Desktop instalado (o script inicia o Docker se ele estiver parado)
- `cloudflared` instalado (o script instala via `winget` se não estiver presente)
- Não é necessário cartão de crédito nem domínio

## Execução

No PowerShell, dentro desta pasta, rode:

```powershell
powershell -ExecutionPolicy Bypass -File .\iniciar-n8n.ps1
```

O script faz, em ordem:

1. Verifica/inicia o Docker Desktop
2. Verifica/instala o `cloudflared`
3. Abre um túnel temporário do Cloudflare e captura a URL gerada
4. Reinicia o n8n com `N8N_PROTOCOL=https`, `N8N_HOST`, `N8N_WEBHOOK_URL` e `N8N_PROXY_HOPS` compatíveis com a URL
5. Copia a URL para a área de transferência, salva em `url-n8n.txt` e abre o navegador

Ao terminar, você verá algo como:

```text
URL do n8n: https://palavras-aleatorias.trycloudflare.com
```

Na primeira vez, crie a conta *owner* do n8n no navegador.

## Containers e dados

Por padrão, o script reaproveita o container existente chamado `n8n`, usando o volume `n8n_data`. Seus workflows e credenciais são preservados; apenas a configuração de webhook é atualizada para a nova URL.

Se não houver um container `n8n`, o script cria `n8n-minicurso` com o volume `n8n_minicurso_data`.

Para criar uma instância separada mesmo com o container `n8n` existente:

```powershell
powershell -ExecutionPolicy Bypass -File .\iniciar-n8n.ps1 -NovaInstancia
```

Se a porta 5678 estiver ocupada, o script escolhe automaticamente outra porta livre.

## Opções

| Opção | Efeito |
| --- | --- |
| `-SemNavegador` | Não abre o navegador automaticamente |
| `-NovaInstancia` | Cria um container isolado em vez de reaproveitar o `n8n` |
| `-Email seu@email.com` | Protege a URL com login por e-mail do Cloudflare |
| `-Parar` | Encerra o túnel e remove apenas o container `n8n-minicurso` |
| `-Porta 5678` | Define a porta local inicial |
| `-NomeContainer n8n-minicurso` | Nome do container criado |
| `-Volume n8n_minicurso_data` | Volume do container criado |
| `-ContainerExistente n8n` | Nome do container a reaproveitar |
| `-VolumeExistente n8n_data` | Volume do container existente |

## Encerrando

```powershell
powershell -ExecutionPolicy Bypass -File .\iniciar-n8n.ps1 -Parar
```

O túnel é encerrado e o arquivo `url-n8n.txt` é removido. O container `n8n` existente continua rodando; o container `n8n-minicurso`, se existir, é removido. Os volumes não são apagados.

## Atenção

- A URL muda a cada execução. Isso é esperado: é um túnel temporário, não uma hospedagem permanente.
- Webhooks externos continuam funcionando porque o script atualiza `N8N_WEBHOOK_URL` a cada execução.
- Com `-Email`, o login por e-mail do Cloudflare bloqueia clientes não interativos, portanto webhooks de serviços externos deixam de funcionar.
- Túneis rápidos não têm SLA, suportam até 200 requisições simultâneas e não são indicados para produção.
- Arquivos gerados: `.logs/` (logs do `cloudflared` e PID) e `url-n8n.txt`.

## Problemas comuns

**“Docker não iniciou”**: abra o Docker Desktop manualmente e rode o script novamente.

**“Nao consegui capturar a URL do tunel”**: verifique `.logs/cloudflared.err.log`. Normalmente é falta de conexão com a internet ou o `cloudflared` desatualizado.

**“Falha ao iniciar o container”**: outra aplicação pode estar usando a porta escolhida. Rode com `-Porta 5679`.

**Página do n8n não carrega**: aguarde alguns segundos. Se o container existente foi reiniciado, o n8n pode levar um pouco para ficar pronto.
