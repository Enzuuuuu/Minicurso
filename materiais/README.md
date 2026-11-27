# Automações de processos com Low Code

Minicurso introdutório sobre automação de processos com **n8n**, uma plataforma de automação low code que permite conectar sistemas, serviços e dados sem exigir conhecimento avançado de programação.

O conteúdo é voltado para **qualquer área** — administrativa, financeira, comercial, de pessoas, suporte, educação, saúde ou operações —, já que a lógica de automação é a mesma: identificar tarefas repetitivas, padronizar decisões e integrar ferramentas que hoje conversam apenas por copiar e colar.

## Sobre o minicurso

Ao longo do minicurso, você vai entender como transformar processos manuais em fluxos automatizados, desde o mapeamento do processo até a execução de um workflow funcional no n8n.

A abordagem é prática: cada conceito é apresentado junto com um exemplo aplicável a diferentes contextos de trabalho.

## O que você vai aprender

- O que é automação de processos e quando ela vale a pena
- O que é low code e como o n8n se encaixa nesse cenário
- Conceitos básicos do n8n: workflows, nodes, triggers e credenciais
- Como mapear um processo antes de automatizá-lo
- Automações com gatilhos manuais, agendados e por eventos (webhook)
- Integrações com ferramentas comuns, como e-mail, planilhas, formulários e APIs
- Boas práticas de segurança, organização e manutenção dos fluxos
- Como evoluir um fluxo simples para um processo mais robusto

## Público-alvo

Qualquer pessoa que queira reduzir tarefas repetitivas no dia a dia, independentemente da área de atuação ou do nível técnico. Não é necessário saber programar.

## Estrutura sugerida

1. **Introdução** — automação, low code e o papel do n8n
2. **Mapeando processos** — entradas, decisões e saídas
3. **Primeiro workflow** — trigger, node e execução
4. **Integrações** — conectando serviços e APIs
5. **Dados e decisões** — condições, transformações e formatação
6. **Segurança e boas práticas** — credenciais, logs e tratamento de erros
7. **Exemplo final** — um processo automatizado de ponta a ponta

## Como usar este repositório

Este repositório reúne os materiais do minicurso. Os exemplos de workflows e os arquivos de apoio poderão ser adicionados aqui ao longo das aulas.

Para executar os exemplos, você pode usar o n8n localmente ou em uma instância hospedada, criando um workflow novo e importando os arquivos disponíveis neste repositório.

## Formulário de solicitação (exemplo final)

O exemplo final usa o Form Trigger nativo do n8n. Com o n8n local na porta padrão, abra:

```text
http://localhost:5678/form/central-atendimento
```

Em uma instância hospedada, substitua `http://localhost:5678` pelo endereço da sua instância.

Materiais desta pasta:

- `enviar-solicitacao.html`: página com o link do formulário, os campos e um passo a passo resumido.
- `TUTORIAL_FORMULARIO.md`: tutorial completo, do preenchimento à verificação do e-mail e da execução.

O solicitante escolhe o setor no formulário. A IA redige o assunto e o corpo da resposta, que são enviados automaticamente por e-mail.

## Licença

Material livre para uso educacional.
