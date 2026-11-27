# Envio de e-mail — registro rápido no n8n

## Onde a lógica está no projeto original

- `C:\Users\Francisco\Desktop\API_N8N\explicacao-workflow.md` — seções 12 e 13 descrevem o envio da resposta e os avisos internos.
- `C:\Users\Francisco\Desktop\API_N8N\attendance.template.json` — nós `Enviar resposta ao solicitante`, `Marcar resposta enviada`, `Tratar falha resposta`, `Notificar setor` e `Notificar crítico`.
- `C:\Users\Francisco\Desktop\API_N8N\workflow.attendance.json` — workflow completo, pronto para importar no n8n.
- `C:\Users\Francisco\Desktop\API_N8N\create-workflow.ps1` e `build-attendance-template.ps1` — geram e atualizam o template.

## Registro rápido

1. Crie ou selecione a credencial **Gmail OAuth2** (`gmailOAuth2`) chamada `Gmail account`.
2. Crie o nó Gmail `Enviar resposta ao solicitante` (`n8n-nodes-base.gmail`, `typeVersion: 2.1`):

```json
{
  "name": "Enviar resposta ao solicitante",
  "type": "n8n-nodes-base.gmail",
  "typeVersion": 2.1,
  "parameters": {
    "sendTo": "={{ $json.email }}",
    "subject": "={{ $json.assunto_resposta }}",
    "emailType": "text",
    "message": "={{ $json.corpo_email }}",
    "options": {
      "appendAttribution": false
    }
  },
  "onError": "continueErrorOutput"
}
```

3. Na saída de sucesso, use um nó `Set` chamado `Marcar resposta enviada` com `envio_resposta=enviada`.
4. Na saída de erro, use um nó `Set` chamado `Tratar falha resposta` com `envio_resposta=pendente`. As duas rotas seguem para `Prioridade crítica?`.
5. Depois disso, configure os avisos internos:

| Nó | Destinatário | Assunto |
| --- | --- | --- |
| `Notificar setor` | `<seu-email-interno>` | `={{ "Solicitação " + $json.solicitacao_id + " - " + $json.setor + " - " + $json.prioridade }}` |
| `Notificar crítico` | `<seu-email-interno>` | `={{ "[CRÍTICO] Solicitação " + $json.solicitacao_id + " - " + $json.setor + " - " + $json.prioridade }}` |

Corpo dos dois avisos:

```text
Solicitação <solicitacao_id>
Setor escolhido: <setor>
Prioridade: <prioridade>
Resumo: <resumo>
Referência: Data Table central_atendimento_v1 / registro #<id>
Resposta ao solicitante: <envio_resposta>
Revisão humana necessária: <revisao_humana>
```

6. A IA deve devolver somente `assunto_resposta` e `corpo_email`. O parser usa `additionalProperties=false`, sem ferramentas e com instrução explícita para tratar a mensagem recebida como dado não confiável.
7. A tabela de apoio é `central_atendimento_v1`; grave `resposta_sugerida` a partir de `corpo_email` antes de enviar.

> Não publique e-mails pessoais, IDs de credencial nem tokens neste repositório. Substitua `<seu-email-interno>` pelo endereço da sua equipe.
