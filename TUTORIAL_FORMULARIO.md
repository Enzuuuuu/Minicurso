# Tutorial - Enviar solicitação pelo formulário

Este tutorial mostra como usar o exemplo final do minicurso: o formulário nativo do n8n que alimenta o workflow `Central de Atendimento - IA`.

## 1. Abrir o formulário

Com o n8n local rodando na porta padrão, acesse:

```text
http://localhost:5678/form/central-atendimento
```

Se você usou `iniciar-n8n.ps1`, pegue a URL temporária em `url-n8n.txt` e monte o endereço assim:

```text
<URL do arquivo url-n8n.txt>/form/central-atendimento
```

Confirme que o workflow está ativo no n8n. O formulário é público e não pede login.

## 2. Preencher os campos

| Campo | Obrigatório | O que informar |
| --- | --- | --- |
| Setor responsável | Sim | `TI`, `Financeiro`, `Administrativo`, `Comercial` ou `Triagem manual`. |
| Nome | Sim | Nome do solicitante. |
| E-mail | Sim | Endereço que receberá a resposta. |
| Assunto | Sim | Resumo curto da solicitação. |
| Mensagem | Sim | Descrição do que aconteceu. |
| Identificador | Não | Código usado para evitar duplicidade. |

Exemplo:

```json
{
  "setor": "TI",
  "nome": "Maria Silva",
  "email": "maria@example.com",
  "assunto": "Erro ao acessar o sistema",
  "mensagem": "Não consigo entrar desde ontem.",
  "identificador": "SOL-2026-0001"
}
```

## 3. Enviar

Clique em **Enviar solicitação**. O n8n confirma com:

> Solicitação recebida. Você receberá a resposta por e-mail em breve.

Não existe mais uma página externa com POST nem um Webhook público. O envio é feito direto no formulário do n8n.

## 4. O que o workflow faz

1. `Normalizar payload` limpa os campos, gera um ID quando necessário e mascara e-mail/telefone antes da IA.
2. `Campos obrigatórios?` valida os dados.
3. `Verificar duplicidade` consulta a Data Table pelo identificador.
4. O Gemini redige `assunto_resposta` e `corpo_email`. O setor não é decidido pela IA.
5. `Registrar solicitação` grava o registro na tabela.
6. `Enviar resposta ao solicitante` envia o e-mail automaticamente.
7. `Notificar setor` ou `Notificar crítico` avisa internamente depois do envio.

## 5. Como verificar o resultado

- Confira a caixa de entrada do e-mail informado, incluindo spam.
- No n8n, abra **Executions** e veja a execução do workflow.
- Em **Data Tables → central_atendimento_v1**, confira a linha com o mesmo identificador.

## 6. Problemas comuns

- **Problem loading form**: o workflow pode estar inativo ou o caminho pode ter sido salvo no campo errado. No Form Trigger, o caminho fica em `parameters.options.path`.
- **Página não abre**: com túnel temporário, a URL muda a cada execução. Use a URL atual de `url-n8n.txt`.
- **E-mail não chegou**: confira o endereço digitado e a pasta de spam. Se a falha foi do Gmail, a execução marca `envio_resposta=pendente`.
- **Duplicidade**: reenviar o mesmo identificador registra a duplicidade e não gera um segundo e-mail.

## 7. Por que este exemplo é didático

Ele mostra, em uma única tela, os conceitos do minicurso: trigger nativo, transformação com Set, decisão com IF/Switch, IA com structured output, persistência em Data Table e integração com Gmail — tudo sem Code nodes.
