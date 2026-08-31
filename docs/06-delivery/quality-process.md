# Processo de qualidade e merge

## 1. Regra de operação

Toda mudança segue a sequência abaixo. Nenhuma IA ou pessoa salta do requisito direto para o código.

`task → plano técnico → testes planejados → implementação → revisão adversarial → CI verde → merge`

Uma task deve usar o [template de task](../../.github/ISSUE_TEMPLATE/task.yml). O PR deve preencher o [template de pull request](../../.github/pull_request_template.md) e atender à [Definition of Done](definition-of-done.md).

## 2. Contrato por task

Antes de editar código, o autor registra:

1. resultado, não-escopo e critérios de aceite;
2. plano técnico: contratos/schema, estados, arquivos, autorização, analytics, risco e rollback;
3. estratégia de teste, priorizando comportamento e risco;
4. hipótese de revisão adversarial: o que outro revisor deve tentar quebrar.

Depois da implementação, um revisor que não escreveu a alteração verifica de modo independente o diff e as evidências. Para tarefas de banco, autorização, token, consentimento, deleção ou analytics, essa revisão inclui Segurança/LGPD; para fluxos de usuário inclui QA.

## 3. Pirâmide de testes

| Camada | Obrigação | Exemplos para Before I Buy |
|---|---|---|
| Unitário | regras puras e estados | transição `collecting_votes → decision_due`, validação de campos, cálculo de prazo, redaction de analytics |
| Integração | fronteiras e persistência | RPC de convite, revogação, voto único/substituição, idempotência, outbox |
| RLS negativo | toda mudança protegida | anônimo sem token, token de outro dilema, dono alheio, leitura da auto-previsão privada |
| E2E crítico | cada handoff do loop | rascunho offline → revisão/publicação → convite web → voto; nas próximas entregas, decisão → reflexão → Reveal |

Cobertura mínima é 80% por superfície modificada. Não use uma cobertura agregada para esconder uma área nova sem testes. Casos de abuso, perda de dados, autorização e estados temporais devem existir mesmo quando a linha já estiver coberta por teste superficial.

## 4. Gates locais e de CI

| Superfície | Gate local e CI | Estado atual |
|---|---|---|
| Repositório | `git diff --check` | ativo agora |
| Banco Supabase | `cd backend`, depois `npm run db:start`, `npm run db:migrate` e `npm run db:test` | ativo agora; pgTAP fica em `backend/supabase/tests/database/` |
| Flutter mobile | `flutter pub get`, formatação, `flutter analyze`, `flutter test --coverage`, cobertura >=80% | ativa quando `apps/mobile/pubspec.yaml` existir |
| Web convidado | `npm ci`, `npm run lint`, `npm run test:coverage`, cobertura >=80% | ativa quando `apps/guest-web/package-lock.json` existir |
| E2E web crítico | `npm run e2e:critical` com Playwright | ativa com o projeto web; o script é obrigatório |

O workflow [Quality gates](../../.github/workflows/quality.yml) roda em pull requests e pushes para `main`. A CLI do Supabase é fixada na pipeline e sobe uma stack Docker isolada; não usa credencial nem banco remoto.

Consulte [Supabase CLI local](supabase-cli-setup.md) para instalação, comandos seguros e a distinção entre reset local e qualquer operação remota.

O baseline de banco ainda possui políticas de acesso direto que não atendem ao contrato negativo recém-adicionado. O job `Database policy tests` deve permanecer bloqueador e ficará vermelho até que uma task específica corrija as políticas e introduza sessões de convidado realmente delimitadas. Não marque o job como opcional nem enfraqueça o teste para obter verde artificial.

## 5. Fluxo crítico da Entrega 1

O E2E obrigatório quando as superfícies existirem cobre:

1. criador cria rascunho offline;
2. reinicia ou reconecta e revisa o rascunho sem publicação automática;
3. publica explicitamente e obtém convite não listado;
4. convidado abre o convite, não vê agregados antes de votar e vota sem conta;
5. o criador vê somente agregados; link revogado não revela dados nem aceita voto.

Decisão, reflexão e Reveal entram no mesmo teste de sistema quando essas entregas forem implementadas. Relógios de 7/30 dias devem ser acelerados, não aguardados em tempo real.

## 6. Branch protection

Depois do primeiro push do workflow, configure `main` no GitHub para exigir pull request, conversa resolvida e os checks abaixo antes do merge:

- `Repository contract`;
- `Database policy tests`;
- `Mobile lint, tests, and coverage`, quando o app mobile existir;
- `Guest web lint, tests, and coverage` e `Guest web critical E2E`, quando a web existir.

Administradores seguem as mesmas regras. Não use `continue-on-error` para lint, cobertura, RLS ou E2E. Exceção temporária só pode ser registrada no Decision Log, com prazo, dono e risco explícito.
