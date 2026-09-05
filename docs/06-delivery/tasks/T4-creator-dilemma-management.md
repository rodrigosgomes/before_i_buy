# Task 4 — gestão privada de dilemas do criador

**Status:** concluída no commit `9666bc0`; CI verde
**Tipo:** vertical slice mobile, RPCs protegidas, persistência local e privacidade
**Entrega relacionada:** [Entrega 1](../../01-product/first-delivery-mini-prd.md)
**Depende de:** [Task 3B — perfil remoto, publicação e compartilhamento](T3B-remote-profile-publish-share.md)

## Resultado e contexto de produto

Como criador autenticado, quero acompanhar meus dilemas publicados, consultar
agregados anônimos após o primeiro voto, compartilhar novamente um convite
ativo, revogá-lo e apagar definitivamente o dilema, para manter controle sobre
o conteúdo privado durante a coleta de perspectivas.

Esta slice fecha os controles de titular previstos na Entrega 1. Ela não muda
o voto bruto nem antecipa decisão, reflexão, Reveal, pontuação ou IA.

## Escopo e não-escopo

### Escopo

- listar somente os dilemas do criador autenticado, com estado, prazo e
  agregados anônimos;
- mostrar estado vazio, zero votos, distribuição após o primeiro voto, convite
  revogado e prazo encerrado;
- conservar em memória a capacidade de compartilhar novamente apenas na sessão
  em que o convite foi publicado, sem persistir o segredo no aparelho;
- revogar o convite em uma confirmação explícita e bloquear imediatamente
  novas aberturas e votos;
- apagar fisicamente o dilema e os dados dependentes em cascata;
- manter a interface consistente após sucesso remoto mesmo quando a limpeza
  local ou uma atualização posterior falhar;
- impedir resposta assíncrona de uma sessão anterior de aparecer ou alterar o
  armazenamento local de outra conta.

### Não-escopo

- decisão do criador, reflexão, Reveal, pontuação, comentários ou razões de voto;
- analytics, transição agendada para `decision_due`, feed, busca, conta ou
  identidade persistente de convidado;
- deploy, banco remoto, beta externo, documentos jurídicos ou lojas.

## Critérios de aceite

1. Usuário anônimo não executa as RPCs e uma conta não lista, revoga ou apaga
   dilemas de outra conta.
2. Agregados incluem somente votos ativos do dilema e são exibidos apenas ao
   criador; zero votos possui estado próprio.
3. Convite revogado deixa de aceitar abertura e voto imediatamente, invalida as
   sessões existentes, desaparece do compartilhamento e não pode ser reativado.
4. Exclusão confirmada remove o dilema e seus votos, participações e sessões em
   cascata e retorna a interface para a lista sem o item.
5. Falha antes da confirmação remota mantém o estado anterior e oferece nova
   tentativa. Falha de limpeza local depois do sucesso remoto não afirma que a
   revogação ou exclusão falhou.
6. O token ou URL completa do convite não fica em `SharedPreferences`, Keychain,
   Keystore, logs, analytics, semântica ou texto de tela; o valor existe somente
   em memória durante a sessão de publicação.
7. Troca de conta ou logout durante abertura, atualização, revogação ou exclusão
   não revela dados nem limpa o convite local da sessão seguinte.
8. O painel funciona a 320 px e texto a 200%, com foco, rótulos e confirmações
   acessíveis.

## Plano técnico

1. Manter RPCs `security definer` com `search_path` fixo, `auth.uid()` obrigatório
   e filtro pelo dono para listagem, revogação e exclusão.
2. Manter exclusão atômica por FK `ON DELETE CASCADE`; a revogação marca o
   dilema e invalida sessões de convidado na mesma transação.
3. Remover a persistência do convite em `SharedPreferences`, manter o valor
   somente em memória e apagar no bootstrap resíduos criados pela implementação
   inicial ainda não liberada.
4. Capturar o repositório local da conta antes de operações assíncronas e tratar
   limpeza local como etapa posterior ao sucesso remoto. A UI usa o resultado
   remoto como autoridade e descarta respostas de sessão obsoleta.
5. Remover artefatos locais de npm/Supabase adicionados ao Git e ignorar esses
   diretórios na raiz do repositório.

## Estratégia de testes

- **Banco/RLS:** anônimo bloqueado, conta alheia bloqueada, agregados exatos,
  revogação de sessões e cascata completa na exclusão.
- **Unidade/contrato mobile:** parse de resposta, RPC e armazenamento seguro
  isolado por conta; convite inválido não é restaurado.
- **Widget/integração:** lista vazia e preenchida, zero/um ou mais votos,
  compartilhar, cancelar/confirmar, falha remota, limpeza local recusada e troca
  de sessão durante cada operação sensível.
- **Sistema local:** cliente Dart autenticado → listar → revogar → confirmar
  bloqueio do convite → apagar → confirmar ausência no Supabase local.
- **Acessibilidade:** painel a 320 px/200% e controles com rótulos semânticos.

## Privacidade, segurança, risco e rollback

As RPCs não concedem acesso direto às tabelas. O app recebe apenas dados do
próprio criador e agregados sem identidade. O token de convite permanece uma
capacidade sensível: o servidor guarda somente SHA-256 e o cliente o conserva
somente em memória para o compartilhamento imediato. Revogar ou apagar também
remove essa cópia; um resíduo local sem validade não reabre acesso no servidor.

O principal risco é um sucesso remoto seguido de falha local ou troca de conta.
O rollback do cliente oculta o painel, enquanto a migration aditiva pode ficar
instalada com execução restrita. Não se reverte exclusão confirmada.

## Foco da revisão adversarial

Produto tenta introduzir decisão/Reveal ou pressão por contagem. Segurança tenta
enumerar outra conta, reusar sessão revogada, obter token no armazenamento comum
e explorar troca de sessão. Privacidade tenta recuperar conteúdo após exclusão.
QA interrompe rede e armazenamento em cada fronteira e reinicia o app antes e
depois de revogar ou apagar.

## Evidências de fechamento

- Flutter: formatação e análise sem apontamentos; suíte completa com 89 testes
  aprovados e 1 teste de sistema separado; cobertura de linhas em 95,58% (mínimo
  de 80%).
- Integração mobile/Supabase local: fluxo autenticado de listar, revogar,
  bloquear sessão antiga e nova abertura, apagar e confirmar ausência aprovado.
- Banco: 5 arquivos pgTAP e 164 testes aprovados; concorrência com 4 cenários
  aprovada; nenhuma migration pendente.
- Edge e web: contratos e runtime aprovados; lint web aprovado; 9 testes web
  aprovados com 94,3% de linhas e 80,9% de branches; E2E crítico com 2 cenários
  aprovado.
- Revisão adversarial de produto, segurança/privacidade e QA concluída sem
  achados P0 ou P1 após as correções.
- CI remota do commit `9666bc0`: contrato do repositório, banco, mobile, web e
  E2E crítico concluídos com sucesso no GitHub Actions.

Analytics e a transição agendada de `collecting_votes` para `decision_due`
continuam como trabalho da Entrega 1, fora da Task 4.
