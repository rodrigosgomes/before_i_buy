## Resultado

<!-- Qual comportamento mudou e qual task/mini-PRD o autoriza? -->

## Escopo

- Incluído:
- Não incluído:

## Plano técnico executado

<!-- Registre contratos/schema, estados, autorização, arquivos tocados, risco e rollback. -->

## Testes e evidências

- [ ] Testes unitários para regras e transições aplicáveis
- [ ] Testes de integração/contrato aplicáveis
- [ ] Testes negativos de RLS para toda alteração de tabela, política ou endpoint protegido
- [ ] Teste offline/reconexão quando há persistência local
- [ ] E2E do fluxo crítico alterado, ou justificativa explícita de por que não se aplica
- [ ] Cobertura da superfície alterada é >= 80%
- [ ] Lint, formatação e testes obrigatórios passaram

<!-- Cole comandos executados, resultado e qualquer teste não executado. -->

## Privacidade e segurança

- [ ] Não há token, URL privada, preço exato, texto livre ou dado pessoal em logs/analytics
- [ ] RLS/autorização foi verificada no servidor, não somente na interface
- [ ] Dados, retenção, consentimento e controles do titular foram revisados quando aplicável

## Revisão adversarial independente

- [ ] Um revisor que não implementou a mudança tentou quebrar estados, autorização, privacidade e regressões.
- Foco e resultado da revisão:

## Risco e rollback

<!-- Descreva risco residual, feature flag, migração reversível ou plano de rollback. -->
