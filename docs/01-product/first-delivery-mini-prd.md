# Mini-PRD — Entrega 1: criar, publicar e votar

**Status:** aprovado para planejamento e implementação interna
**Data:** 2026-08-30
**Escopo:** primeira entrega técnica; não é o MVP fechado nem uma liberação para beta público.

## 1. Papel desta entrega

O MVP completo prova o loop `Tentação → Previsão → Pausa → Decisão → Reflexão → Reveal → Autoconhecimento`. Esta primeira entrega implementa os dois primeiros handoffs reais e estabelece contratos que não impedem o fechamento posterior do loop:

`rascunho local → publicação privada → convite → voto do convidado`

Ela testa se um criador consegue expor um dilema de compra de forma confortável e se uma pessoa convidada vota sem instalar o app. Não mede, ainda, a hipótese de reflexão ou Reveal.

Em caso de conflito, este documento vale para a Entrega 1; decisões aceitas no [Decision Log](../06-delivery/DECISION_LOG.md) têm precedência sobre documentos de apoio.

## 2. Problema, usuário e hipótese

**Problema.** A dúvida de compra costuma ficar espalhada entre loja, conversa e memória. O criador precisa de uma pausa simples; o amigo precisa opinar sem instalar ou cadastrar-se.

**Usuários.** Adultos no Brasil que já pedem opinião a amigos próximos sobre compras discricionárias. O criador usa o app mobile; o convidado abre um link em uma página web responsiva.

**Hipótese E1.** Um criador conseguirá publicar um dilema privado em menos de dois minutos e pelo menos metade dos visitantes elegíveis do convite conseguirá votar em menos de vinte segundos, sem conta.

## 3. Escopo funcional

### Criador autenticado

- Confirma maioridade, aceita Termos e Aviso de Privacidade e define o nome de exibição usado somente na página de convite antes de publicar.
- Cria um rascunho local, explicitamente não compartilhado, com:
  - nome do item (2–80 caracteres);
  - preço positivo em BRL, persistido internamente em centavos e com modelo compatível com ISO 4217;
  - categoria;
  - motivo (10–500 caracteres);
  - finalidade `para mim` ou `presente`;
  - janela de pausa: 24 horas, 3 dias ou 7 dias.
- Recupera um rascunho após interrupção ou reconexão. Nenhum rascunho é publicado automaticamente.
- Revisa o conteúdo e publica explicitamente; a publicação cria um convite privado e não listado.
- Compartilha o convite pela folha nativa de compartilhamento.
- Consulta, de forma privada, contagem e agregados de votos após existir ao menos um voto.
- Revoga o convite em um toque e pode apagar o dilema. A revogação bloqueia imediatamente novas visualizações e votos pelo link.

### Convidado sem conta

- Abre um convite válido em uma página web mobile-first, sem tela de cadastro.
- Vê o nome do criador, item, preço, categoria, motivo e prazo da pausa; esses dados aparecem somente depois de validar o convite, nunca na prévia social do link.
- Responde uma previsão: `Comprar — provavelmente vai ficar feliz`, `Esperar — ainda é cedo` ou `Deixar pra lá — provavelmente vai ficar feliz`.
- Pode alterar a própria previsão até o prazo, na mesma sessão de convidado; há somente uma previsão ativa por sessão e dilema.
- Não vê agregados antes de votar. Depois do voto, vê a confirmação e os agregados sem identidades, razões ou ranking.

## 4. Fora de escopo

- imagens, upload de mídia e URLs de produto;
- razão textual do voto, comentários, chat, denúncia ou bloqueio de participante;
- assinatura de Reveal, notificações, histórico, pontuação, decisão, reflexão, Reveal e jobs de 7/30 dias;
- auto-previsão do criador e qualquer funcionalidade de IA;
- feed público, busca, seguidores, importação de contatos, publicidade, afiliados, Open Finance ou gamificação de pressão;
- conta, e-mail, push ou nome persistente para convidados;
- opção de tornar prévias sociais específicas do item.

Essas exclusões reduzem simultaneamente o raio de implementação, a coleta de dados e a superfície de moderação. A próxima entrega começa em `decision_due` e adiciona decisão do criador; ela não pode reinterpretar votos ou quebrar as regras de acesso desta entrega.

## 5. Estados e regras de transição

| Domínio | Estado | Evento | Próximo estado | Regra |
|---|---|---|---|---|
| Rascunho local | `local_draft` | reconexão | `review_required` | Permanece local e sem audiência. |
| Rascunho local | `local_draft` ou `review_required` | publicar explicitamente | `collecting_votes` | Cria o dilema no servidor, o convite e o prazo. |
| Dilema | `collecting_votes` | prazo alcançado | `decision_due` | Novos votos são recusados; a Entrega 2 tratará a decisão. |
| Convite | `active` | revogar | `revoked` | Link não revela conteúdo nem aceita voto. |
| Dilema ativo | qualquer estado ativo | apagar | `deleted` | Revoga acessos e inicia a remoção em cascata. |

Invariantes:

- somente o criador publica, revoga ou apaga seu dilema;
- o trabalhador agendado marca o prazo, mas nunca escolhe uma decisão pelo criador;
- sessão de convidado é limitada a um único dilema e não concede leitura de outro objeto;
- o voto armazena a escolha bruta, sem pontuação nesta entrega, para que o Reveal posterior aplique regras versionadas;
- `local_draft` não é uma linha publicada no banco e usa chave de idempotência quando for sincronizado.

## 6. Critérios de aceite

### Fluxo e experiência

- Em teste de usabilidade, a mediana de criação e publicação é inferior a dois minutos.
- Em teste de usabilidade, a mediana de voto do convidado é inferior a vinte segundos.
- O criador vê uma prévia fiel da página do convidado antes de compartilhar.
- O rascunho recuperado exibe **Rascunho — não compartilhado** e exige revisão e publicação explícita.
- O convidado não encontra muro de cadastro, nem precisa informar e-mail, contato ou nome para votar.
- Agregados de voto não podem ser inferidos por interface ou API antes da submissão.
- Um voto posterior na mesma sessão substitui o anterior até `decision_due`; não cria uma segunda previsão ativa.
- Link revogado, inválido ou vencido devolve uma tela genérica sem nome, preço, motivo ou outra informação do dilema.

### Privacidade e segurança

- Todo dilema é privado e não listado; não existe listagem pública, sitemap de convites ou busca.
- Prévia OpenGraph é sempre neutra: não inclui item, preço, foto, criador nem o token. Não há opt-in de prévia específica nesta entrega nem no MVP atual.
- O convite possui ao menos 128 bits de entropia; somente seu hash SHA-256 é persistido. Tokens e URLs completos não aparecem em logs, erros, analytics ou `Referer`.
- A autorização é aplicada no servidor e em RLS: convidado sem escopo válido não enumera dilemas; criador não acessa dilema alheio; sessão de um convite não acessa outro convite.
- O app avisa, antes do compartilhamento, que links podem ser encaminhados e oferece revogação imediata.
- O criador pode apagar o dilema e seus votos; a remoção imediatamente bloqueia o acesso e conclui a remoção dos registros da entrega conforme a política de retenção.
- Eventos analíticos não recebem nome do item, motivo, preço exato, token, URL, imagem nem identificador pessoal do convidado.

### Qualidade técnica mínima

- Validadores de campos, regras de transição, expiração, voto único/substituição e revogação têm testes unitários.
- Políticas RLS e endpoints têm testes negativos para anônimo, convite inválido, convite de outro dilema e criador de outro dilema.
- Há E2E para rascunho offline → revisão → publicação, convite → voto e convite revogado.
- A página web atende às verificações de teclado, foco, contraste, leitura por leitor de tela e texto ampliado nos fluxos críticos.

## 7. Privacidade por design

| Dado nesta entrega | Finalidade | Regra de minimização |
|---|---|---|
| Conta e confirmação de maioridade do criador | autoria, controle e elegibilidade | manter identificador de autenticação separado do perfil; não coletar data de nascimento sem base legal aprovada. |
| Item, preço, categoria e motivo | contextualizar o dilema privado | banco do produto somente; preço exato e texto livre não entram em analytics. |
| Token de convite | acesso limitado a um dilema | gerar com alta entropia, persistir apenas hash, revogar e impedir vazamento em logs/referrer. |
| Sessão pseudônima do convidado e voto | evitar duplicidade e registrar previsão | sem e-mail, push ou nome persistente; escopo de um dilema; rate limit como proteção, não como identidade. |
| Eventos de uso | validar hipótese E1 | IDs pseudônimos e propriedades agregadas permitidas. |

Antes de qualquer beta externo, continuam obrigatórios: revisão jurídica de maioridade/LGPD, base legal e aviso de privacidade; política de retenção e backups; fluxo de exclusão de conta; modelo de ameaça e resposta a incidentes.

## 8. Métricas e eventos

**Indicadores de sucesso da entrega**

- ativação do criador: primeiro dilema publicado em até 7 dias, meta inicial `≥ 40%`;
- conversão de voto: votos válidos / visitantes únicos elegíveis, meta inicial `≥ 50%`;
- liquidez inicial: dilemas com ao menos dois votos em 24 horas, meta inicial `≥ 60%`;
- mediana de criação `< 2 min` e mediana de voto `< 20 s`.

**Guardrails**

- qualquer acesso não autorizado, vazamento de convite ou prévia não neutra bloqueia a liberação;
- revogação ou exclusão em até dez minutos acima de 5% dos dilemas publicados indica problema de expectativa de privacidade;
- erros de publicação, recuperação ou voto são acompanhados por etapa, sem conteúdo sensível.

**Eventos permitidos**

`dilemma_create_started`, `dilemma_draft_saved`, `offline_draft_recovered`, `offline_draft_publish_reviewed`, `dilemma_published`, `dilemma_share_invoked`, `invite_opened`, `vote_submitted`, `vote_changed`, `invite_link_revoked`, `dilemma_deleted`.

As propriedades obedecem à taxonomia já definida: ID pseudônimo, categoria, finalidade, faixa de preço calculada no servidor, janela de pausa e presença de falha. Texto livre, valor exato e segredo de convite são proibidos.

## 9. Decisões consolidadas e pendências

| Tema | Estado | Definição para a Entrega 1 | Próximo dono/momento |
|---|---|---|---|
| Loop de produto | Aceito | Esta entrega cobre criação, convite e previsão; preserva a transição para decisão e Reveal. | Produto antes da Entrega 2. |
| IA no produto | Aceito | Nenhuma IA, recomendação, resumo ou previsão automatizada. | Reavaliar somente após beta e evidência de dor. |
| Privacidade de prévia | Aceito | OpenGraph sempre neutro, sem exceção de dono. | Engenharia e revisão de privacidade. |
| Preço | Decisão de escopo | Obrigatório e visível somente para quem abre um convite válido; ocultação por audiência fica fora da Entrega 1. | Validar em teste de beta antes de expandir. |
| Identidade de convidado | Decisão de escopo | Sem nome persistente nem contato; sessão pseudônima limitada a um dilema. | Produto/segurança antes de razões e histórico. |
| Abuso de voto | P0 técnico | Definir rate limit, duração de sessão e detecção mínima sem usar IP como identidade. | Spike de segurança antes do schema final. |
| Stack/backend | P0 técnico | Flutter mobile + web leve para convidado já são a direção; Supabase/Postgres precisa concluir spike de RLS, jobs, região, backup e deleção. | Arquitetura antes de aprovar a migration da Entrega 1. |
| Schema já versionado | P0 técnico | As migrations atuais antecipam mídia, razões e nome persistente de convidado, todos fora deste escopo. A Entrega 1 deve usar uma nova migration aditiva para permitir convidado sem nome e manter campos adiados sem exposição. Não reescrever migrations históricas. | Banco/segurança antes da implementação da persistência de voto. |
| Maioridade e LGPD | P0 de liberação externa | Autoafirmação +18 no fluxo; revisão jurídica, bases legais e retenção aprovadas antes de beta externo. | Responsável de privacidade/jurídico. |
| Imagens, URLs e razões | Adiado | Não entram na primeira entrega para não antecipar storage, EXIF, sanitização de URL e moderação de texto. | Planejar após a entrega E1. |
| Reflexão, Reveal e pontuação | Adiado | Não implementar nem inferir acertos; votos guardam fatos brutos e sem score. | Mini-PRD da Entrega 2 e 3. |

## 10. Definition of done

A Entrega 1 está concluída quando todos os critérios de aceite e testes acima passam, a matriz de autorização é revisada independentemente, o dashboard recebe somente eventos permitidos e um teste manual comprova criação, votação, revogação e ausência de dado privado na prévia do link.
