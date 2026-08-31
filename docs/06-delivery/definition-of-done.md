# Definition of Done

Uma task está pronta para merge apenas quando satisfaz todos os itens aplicáveis abaixo. A ausência de um item exige justificativa explícita no PR e aprovação do responsável de qualidade; ela não é presumida pela urgência da entrega.

## 1. Produto e escopo

- A task referencia um mini-PRD, requisito ou decisão aceita.
- Critérios de aceite observáveis foram atendidos, incluindo estados de erro, vazio e permissão quando aplicável.
- Não-escopo permanece fora do diff; toda expansão foi aprovada e registrada.
- Mudanças de comportamento atualizam documentação, analytics ou Decision Log quando necessário.

## 2. Plano e implementação

- O plano técnico foi registrado antes da implementação, com contratos/schema, estados, módulos, risco, rollback e impacto de privacidade.
- A solução é uma vertical slice pequena, tipada e sem abstração especulativa.
- Migrações são aditivas, versionadas e reversíveis por plano documentado; migrations históricas não são reescritas.
- Não há segredo, token, URL privada, preço exato ou texto livre em código cliente, logs ou analytics.

## 3. Testes e cobertura

- Regras novas ou alteradas têm teste unitário antes ou junto da implementação.
- Integrações, contratos e persistência têm testes quando a task cruza processo, rede, banco ou armazenamento.
- A cobertura de linhas de cada superfície alterada (mobile, web e backend quando mensurável) é no mínimo 80%; cobertura não substitui cenários de risco.
- Fluxos críticos alterados têm E2E ou integração de sistema que exercite o comportamento real de ponta a ponta.
- Persistência local exige teste offline → reinício/reconexão → revisão/publicação explícita.

## 4. Segurança, privacidade e dados

- Toda tabela, política, função ou endpoint protegido possui testes negativos de autorização para os papéis afetados.
- RLS é deny-by-default; acessos de convidado são limitados a um dilema e nunca dependem apenas de esconder controles na UI.
- Convites, deleção, retenção, consentimento e eventos analíticos seguem o PRD e a política de privacidade.
- Para alterações de schema, os testes cobrem ao menos: anônimo sem token, escopo de outro dilema, usuário autenticado em objeto alheio e isolamento de dados privados do criador.

## 5. Revisão e entrega

- Formatação, análise estática, testes, cobertura e jobs obrigatórios de CI passaram.
- Um revisor independente faz revisão adversarial: tenta quebrar transições, autorização, privacidade, concorrência e regressões do fluxo afetado.
- O PR registra comandos executados, evidências, risco residual e plano de rollback.
- Não há falha crítica/alta conhecida, gate ignorado ou `continue-on-error` em job obrigatório.
