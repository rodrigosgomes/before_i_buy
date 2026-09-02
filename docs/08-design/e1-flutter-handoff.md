# Entrega 1 — Handoff do Figma Make para Flutter

**Status:** pronto para orientar a futura implementação mobile; não implementa
telas nem altera o escopo da Entrega 1.

## 1. Objetivo e precedência

O export local do Figma Make em [`figma/src`](figma/src/) é a referência visual
e de composição para as telas do criador. Ele não é uma fonte de regras de
produto, de persistência ou de autorização.

Antes de qualquer implementação Flutter, aplicar esta ordem de precedência:

1. [Mini-PRD da Entrega 1](../01-product/first-delivery-mini-prd.md);
2. [Decision Log](../06-delivery/DECISION_LOG.md);
3. [Contrato compartilhado do design system](e1-design-system-contract.md);
4. [Prompts das 11 telas](e1-11-screen-agent-prompts.md);
5. este handoff;
6. `figma/src/App.tsx`, `figma/src/components/Bib.tsx` e
   `figma/src/index.css`.

Em particular, o export é uma demonstração React/Tailwind: não copiar seus
valores arbitrários, seus atalhos de navegação ou seus dados de fixture como
comportamento de produção. O Flutter deverá implementar os contratos `Bib*`,
a máquina de estados aprovada e os dados reais de cada vertical slice.

## 2. Escopo Flutter desta entrega

O app Flutter implementa somente o fluxo do criador:

`E1-S01 → E1-S02 → E1-S03 → E1-S04 → E1-S05 → E1-S06`

As telas `E1-S07` a `E1-S11` pertencem ao cliente Web do convidado. A exceção
é `E1-S04`: o Flutter apresenta uma prévia fiel, porém inerte, do convite Web.
Ela não cria sessão de convidado, não envia voto e não deve carregar o cliente
Web dentro do aplicativo.

Ficam fora desta implementação: imagens e URLs de produto, razão/comentário de
voto, conta ou nome de convidado, decisão, reflexão, Reveal, pontuação, IA,
feed, busca e analytics com conteúdo sensível.

## 3. Fonte visual que pode ser reaproveitada

| Fonte do export | Reuso em Flutter | Limite |
|---|---|---|
| `App.tsx` | Ordem da informação, cópia canônica, composição e estados de exemplo | Não reutilizar estado React, fixtures ou navegação do protótipo |
| `components/Bib.tsx` | Anatomia e nomenclatura dos componentes `Bib*` | Recriar com widgets Flutter e sem depender de SVG/HTML React |
| `index.css` | Valores de cor, tipografia, foco e movimento | Usar somente tokens já aprovados no contrato compartilhado |
| `imports/*.md` | Contexto de produto, prompts de tela e acessibilidade | Mini-PRD e Decision Log continuam prevalecendo |

O viewport de referência é `393 × 852 px`. A fidelidade não se mede por uma
posição fixa: a tela deve continuar utilizável a 320 px de largura e com texto
em escala de 200%.

## 4. Fundação obrigatória antes das telas

Primeiro materializar no adaptador Flutter o trabalho `E1-DS00` definido no
contrato. A composição das telas só começa depois que os seguintes widgets e
estados existirem e tiverem catálogo/golden próprio:

- `BibPageShell`, `BibTopBar`, `BibBrandMark` e `BibBottomActionBar`;
- `BibPrimaryButton`, `BibSecondaryButton` e `BibTextButton`;
- `BibTextField`, `BibCurrencyField`, `BibSelectField` e
  `BibSegmentedChoice`;
- `BibDraftBanner`, `BibPrivacyNotice`, `BibDilemmaSummary`,
  `BibGuestPreviewFrame`, `BibStatusChip`, `BibEmptyState`,
  `BibLoadingBlock` e `BibInlineMessage`;
- `BibVoteOption` apenas para a prévia inerte de `E1-S04`;
- tema Material 3 e tokens semânticos do contrato, com Manrope para display e
  Inter para interface, incluindo fallbacks.

Os wrappers `Bib*` são a API de tela. Não colocar cores, raios, durações ou
semântica local diretamente nas telas para "aproximar" o protótipo.

## 5. Mapa de implementação por tela

| Tela | Intenção e composição a preservar | Estado de produto e ações | Componentes principais |
|---|---|---|---|
| `E1-S01` Home vazia | Hero acolhedor, três capítulos e uma ação dominante; deixar claro que o espaço é privado | Entrada inicial, carregamento curto, indisponível com nova tentativa; iniciar criação local | `BibPageShell`, `BibBrandMark`, `BibEmptyState`, `BibPrivacyNotice`, `BibPrimaryButton` |
| `E1-S02` Nova tentação | Formulário único, pergunta expressiva sobre o motivo e escolhas de finalidade/pausa | Salvar somente `local_draft`; validação 2–80, preço BRL positivo, motivo 10–500; recuperação/offline; **Revisar** nunca publica | campos `Bib*`, `BibDraftBanner`, `BibBottomActionBar` |
| `E1-S03` Revisão | Resumo editorial, motivo em destaque, pausa e confirmação de que nada foi compartilhado | `local_draft` ou `review_required`; editar preserva valores; rascunho recuperado exige revisão explícita | `BibDilemmaSummary`, `BibDraftBanner`, `BibPrivacyNotice`, botões primário/secundário |
| `E1-S04` Prévia | Moldura fiel da parte superior da página de voto, aviso de link encaminhável e CTA explícito | Inerte: exibir **“Prévia — nenhuma ação será enviada”**, desabilitar voto/envio; voltar preserva rascunho; continuar prepara publicação, mas não publica | `BibGuestPreviewFrame`, `BibDilemmaSummary`, `BibVoteOption`, `BibPrivacyNotice`, barra de ação |
| `E1-S05` Publicado e compartilhar | Confirmação breve, status privado/não listado, resumo compacto e aviso de prévia social neutra | Somente após publicação explícita bem-sucedida: `collecting_votes`; CTA abre a folha nativa de compartilhamento; tratar erro/retry sem criar convite duplicado | `BibStatusChip`, `BibDilemmaSummary`, `BibPrivacyNotice`, botão com ícone de compartilhar |
| `E1-S06` Dilema ativo sem votos | Estado vazio sem pressão, prazo como informação e reenvio opcional | `collecting_votes` sem agregado; reabrir compartilhamento e gerenciar/revogar convite; nunca mostrar voto individual ou inventar contagem | `BibStatusChip`, `BibDilemmaSummary`, `BibEmptyState`, `BibPrivacyNotice`, ações de compartilhar/gerenciar |

O fixture `Lu / Fone com cancelamento de ruído / R$ 2.400,00` é permitido
somente para catálogo, golden e validação visual. A interface em produção usa
os dados do rascunho ou dilema autorizado.

## 6. Ajustes necessários em relação ao export

| Ponto | Decisão para Flutter |
|---|---|
| Navegador de telas e botão de desenvolvimento em `E1-S07` | São somente recursos de demonstração; não entram no app nem no Web de produção. |
| `E1-S04` no export | Acrescentar a faixa visível **“Prévia — nenhuma ação será enviada”** e garantir que as três opções sejam inertes, como exige o prompt da tela. |
| Ações de publicação | Não simular sucesso local. A publicação é explícita, idempotente e somente então cria convite privado. |
| Compartilhamento | Chamar a folha nativa do sistema; não construir uma lista própria de mensageiros. |
| Sinalização de estados | Usar texto, ícone, borda e semântica, além de cor. Comprar, Esperar e Deixar pra lá têm o mesmo peso moral. |
| Prévia social | Continuar neutra: não incluir item, preço, motivo, criador ou token. A prévia dentro do app não autoriza metadados OpenGraph específicos. |
| Conteúdo do convidado | A prévia mobile deve refletir a ordem e os componentes do Web real, mas dados do convite só aparecem na Web depois de validado o token. |

## 7. Contratos de acessibilidade e interação

- preservar ordem de leitura e foco: título → contexto → campos/conteúdo →
  aviso de privacidade → ação;
- aplicar `Semantics` com rótulos, estado selecionado, erro e progresso
  anunciáveis; campos mantêm rótulos persistentes;
- garantir alvo mínimo de 48 × 48 px, contraste AA e foco visível quando houver
  teclado/controle externo;
- permitir scroll, reflow e barra de ação não fixa quando teclado ou texto
  ampliado ocupar espaço; não reduzir fonte para caber;
- respeitar redução de movimento; transições têm 200–300 ms e seleção no máximo
  escala `1.02`;
- estados de carregamento nunca revelam título, preço ou motivo antes de a
  autorização correspondente concluir.

## 8. Sequência de trabalho futura

1. Criar o adaptador Flutter de tokens e o catálogo `Bib*` (E1-DS00).
2. Implementar e testar o rascunho local, suas validações e recuperação.
3. Compor `E1-S01` a `E1-S04` sobre esse estado, incluindo a prévia inerte.
4. Integrar publicação idempotente e só então `E1-S05`/`E1-S06`.
5. Comparar `E1-S04` com o cliente Web E1-S08 usando o fixture canônico.
6. Fazer revisão adversarial de produto, privacidade/segurança e QA antes do
   merge, conforme o processo de qualidade.

Essa ordem evita uma tela de sucesso sem contrato de publicação, ou uma prévia
que exponha conteúdo por caminhos diferentes do convite real.

## 9. Testes planejados

| Camada | Evidência mínima |
|---|---|
| Widget/golden | Cada estado de `Bib*`; as seis telas em 393 px, 320 px e texto 200%; estados vazio, carregando, erro, selecionado e desabilitado aplicáveis |
| Unidade | Validadores de rascunho, conversão BRL para centavos, escolha de pausa, transições `local_draft → review_required → collecting_votes` e redaction de dados sensíveis |
| Integração mobile | Offline → reinício/reconexão → revisão explícita; publicação idempotente; retry de falha; share sheet abstraída/mocada; revogação bloqueia reuso do convite |
| Semântica | Rótulos dos campos, opções, banners, mensagens de erro e ação principal; leitura correta da prévia inerte |
| Visual cruzado | Ordem e conteúdo de `BibDilemmaSummary` e opções de voto de `E1-S04` iguais aos contratos do Web; não se exige pixel a pixel entre runtimes |

Nenhum teste pode contornar RLS, expor tokens, registrar texto livre/preço exato
em analytics ou exibir agregados antes de um voto válido.

## 10. Registro de handoff por tela

Ao concluir cada tela, registrar no PR/task o formato abaixo, exigido pelo
contrato compartilhado:

```text
Screen: E1-Sxx
Tokens consumed: [...]
Components reused: [...]
Components added/modified: [...]
States delivered: [...]
Verifications: contrast, 200% text, keyboard, screen reader, reduced motion
Pending issues or contract deviations: none | describe
```

Para `E1-S04`, anexar também a comparação explícita com E1-S08 Web e confirmar
que nenhum voto pode ser enviado pela prévia.
