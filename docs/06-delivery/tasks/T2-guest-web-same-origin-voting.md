# Task 2 — web de convidado e proxy same-origin

**Status:** implementação e validação local concluídas; sem deploy  
**Tipo:** vertical slice web, segurança e qualidade  
**Entrega relacionada:** [Entrega 1](../../01-product/first-delivery-mini-prd.md)  
**Depende de:** [Task 1 — voto de convidado e agregados pós-voto](T1-guest-vote-submission-and-aggregates.md)

## 1. Resultado e contexto de produto

Como convidado sem conta, quero abrir um convite privado, enviar uma previsão e
ver a distribuição anônima somente depois do meu voto, sem instalar aplicativo
nem expor o dilema em uma prévia pública.

Esta task fecha no navegador o handoff `convite → cookie de sessão → voto →
agregados` da Entrega 1. Ela materializa a DEC-012: o navegador fala somente
com o domínio do cliente web; um proxy server-side preserva o caminho e os
cookies estritos até a Edge Function.

## 2. Escopo e não-escopo

### Escopo

- criar `apps/guest-web` em Next.js, responsivo e mobile-first;
- expor um proxy same-origin em `/functions/v1/guest-invite` e
  `/functions/v1/guest-invite/vote`, encaminhando exclusivamente ao endpoint
  configurado da Edge e preservando `Origin`, `Cookie`, `Set-Cookie`, status e
  headers de privacidade;
- implementar os estados E1-S07 a E1-S11: abertura segura, escolha,
  envio, confirmação e agregados pós-voto;
- manter três opções de igual peso (`buy`, `wait`, `skip`), permitir troca
  antes e depois do envio e nunca exibir agregados antes de sucesso;
- criar testes de unidade/integração do proxy e da máquina de estados da tela,
  mais E2E Playwright do fluxo por proxy, erro genérico, revogação e ausência
  de agregados pré-voto;
- ativar os gates web existentes de lint, cobertura >=80% e E2E crítico.

### Não-escopo

- criação, rascunho offline, publicação, revogação ou painel do criador;
- conta, login, e-mail, nome, razão de voto, comentários, opt-in de Reveal,
  decisão, reflexão, pontuação, ranking ou IA;
- analytics de produto, OpenGraph específico, imagem, URL de produto ou feed;
- deploy, domínio público, `supabase link`, segredo remoto ou beta externo.

## 3. Critérios de aceite

1. Abrir `/invite/[token]` inicialmente mostra apenas conteúdo neutro e não
   inclui dados do dilema no HTML, título ou erro.
2. O cliente chama apenas caminhos same-origin; não conhece URL, chave ou
   domínio Supabase no bundle do navegador.
3. O proxy encaminha `POST`, `Origin` e cookie ao upstream permitido, repassa
   `Set-Cookie` sem alargar o `Path` e não cria CORS com credenciais.
4. Após convite válido, a tela apresenta somente os campos permitidos pelo PRD
   e as três previsões sem peso moral desigual.
5. Antes de resposta de voto bem-sucedida não há contagem, porcentagem ou dica
   inferível de agregados; após sucesso há confirmação e, por ação explícita,
   distribuição anônima com soma consistente.
6. Erro, `404` e `429` exibem a mesma tela genérica, sem conteúdo privado, e
   preservam uma escolha ainda não enviada quando houver falha recuperável.
7. Teclado, foco visível, rótulos semânticos, contraste AA, targets de pelo
   menos 48 px e `prefers-reduced-motion` são cobertos no fluxo crítico.
8. Lint, testes com >=80% de cobertura por superfície alterada e Playwright
   crítico passam localmente; o E2E prova que o navegador recebe o cookie pelo
   proxy, vota e não vê agregados antes do voto.

## 4. Plano técnico antes do código

1. Adicionar projeto Next.js enxuto, com TypeScript, CSS sem biblioteca de UI
   e rotas `app/invite/[token]/page.tsx` e `app/functions/v1/guest-invite`.
   O bundle do cliente recebe apenas o token presente na URL e dados retornados
   após validação; `GUEST_INVITE_EDGE_ORIGIN` fica exclusivamente no servidor.
2. Implementar uma única função de proxy allowlist para os dois caminhos.
   Ela rejeita métodos/caminhos inesperados, usa URL absoluta configurada no
   servidor, encaminha somente headers necessários e replica `Set-Cookie`,
   `Cache-Control`, `Referrer-Policy` e `X-Robots-Tag`. Não segue redirects.
3. Separar estado e transporte: o componente cliente começa em carregamento,
   abre o convite, permite seleção local, envia o voto e só então transita para
   confirmação/agregados. Respostas fora do contrato tornam-se indisponíveis.
4. Usar os tokens e componentes mínimos `BibPageShell`, `BibBrandMark`,
   `BibDilemmaSummary`, `BibVoteOption`, `BibPrimaryButton`,
   `BibInlineMessage` e `BibVoteDistribution`, derivados do contrato E1.
5. Risco principal: proxy perder múltiplos `Set-Cookie`, caminho ou `Origin`.
   O rollback é remover a aplicação/rota antes de qualquer deploy; nenhuma
   migration ou contrato de banco é alterado.

## 5. Estratégia de testes

| Camada | Cenários obrigatórios |
|---|---|
| Unitário | allowlist de upstream/métodos/headers; cópia de `Set-Cookie`; validação do contrato de convite/voto; transições loading, seleção, confirmação e indisponível. |
| Integração web | proxy encaminha cookie e origem, não vaza segredo, mantém `Path=/functions/v1/guest-invite`, não emite CORS com credenciais e converte falha inesperada em erro genérico. |
| RLS negativo | não alterado nesta task; a suíte pgTAP/Edge da Task 1 permanece obrigatória e não será enfraquecida. |
| E2E crítico | navegador abre convite pelo proxy, não vê agregado, envia previsão, recebe confirmação, abre agregados, troca previsão e recebe erro genérico para convite revogado. |
| Acessibilidade | ordem de Tab, foco após loading/erro, nomes acessíveis, opções de rádio e redução de movimento. |

## 6. Privacidade e segurança

- Não persistir dados no browser além do cookie `HttpOnly` emitido pela Edge;
  não usar localStorage para token, voto ou perfil.
- Não registrar token, cookie, URL completa, item, preço ou motivo. Não criar
  analytics nesta task.
- O token da URL não entra em metadados, OpenGraph nem saída de erro; a rota
  usa `noindex`, `no-store` e `no-referrer`.
- O proxy tem allowlist fixa e segredo de upstream apenas no ambiente servidor.
  Não é um proxy genérico, não aceita URL no request e não amplia o escopo do
  cookie.

## 7. Foco da revisão adversarial

Produto deve tentar revelar agregados, conta ou julgamento moral antes do voto.
Segurança deve tentar chamar Supabase diretamente, alterar o destino do proxy,
perder `Origin`/cookie, induzir CORS credenciado e vazar token em HTML/logs.
QA deve interromper abertura/envio, retornar `404`/`429`, recarregar após voto,
trocar escolha e navegar só por teclado em 320 px.

## 8. Definition of Done

- revisão de produto antes da implementação;
- testes planejados adicionados antes ou junto da implementação;
- revisão paralela de Segurança/LGPD e QA sem P0/P1 aberto;
- gates web, backend aplicável e `git diff --check` verdes;
- Task 1 atualizada somente quando o E2E browser comprovar a DEC-012;
- nenhum deploy, link remoto, publicação, commit ou push sem pedido explícito.

## 9. Evidência de implementação e revisão adversarial

### Resultado

- `apps/guest-web` usa Next.js e mantém o token fora do HTML inicial da página;
- o proxy server-side só aceita os dois caminhos da DEC-012, preserva os headers
  necessários e não repassa CORS do upstream;
- o fluxo cobre abertura neutra, seleção, envio, confirmação, agregados somente
  após voto e alteração posterior da previsão;
- falhas `404` e `429` usam a mesma experiência genérica e não expõem o dilema.

### Gates locais

- `npm run lint` — passou;
- `npm run test:coverage` — 9 testes, 94,30% linhas, 80,90% ramos e 100% funções;
- `npm run build` — passou com Next.js 16.3.4;
- `npm run e2e:critical` — 2 cenários Playwright passaram, incluindo cookie
  restrito ao path e mudança de palpite;
- gates backend da Task 1 reexecutados: pgTAP (125), concorrência (4), contrato
  Edge (13; 95,53% linhas) e smoke de runtime.
- `npm audit --json` — nenhuma vulnerabilidade de produção ou desenvolvimento;
  Next.js, Playwright e Vitest foram atualizados antes da validação final.

### Revisão adversarial consolidada

- **Produto:** não há IA, conta, motivo textual, Reveal, score ou agregado antes
  do voto. A possibilidade de alterar a previsão após abrir os agregados foi
  identificada na revisão e implementada antes da validação final.
- **Segurança/LGPD:** o browser não recebe URL/segredo do upstream; o proxy tem
  allowlist, não aceita destino controlado pelo request, repassa `Origin` e
  cookie restrito e não injeta CORS credenciado. Não há analytics ou persistência
  local de token/voto.
- **QA:** o E2E exercita ausência de agregado antes do voto, emissão e reuso do
  cookie via proxy, alteração de voto e convite indisponível genérico. RLS não
  mudou; sua suíte negativa existente foi reexecutada.

Não há P0/P1 local aberto. O deploy e a configuração HTTPS/segredos no ambiente
alvo seguem explicitamente fora do escopo desta task.
