# Task 3 — mobile do criador: rascunho, revisão, publicação e compartilhamento

**Status:** concluída para uso interno; Tasks 3A e 3B revalidadas pela Task 6
**Tipo:** vertical slice mobile, privacidade e integração  
**Entrega relacionada:** [Entrega 1](../../01-product/first-delivery-mini-prd.md)  
**Depende de:** [Task 2 — web de convidado](T2-guest-web-same-origin-voting.md)

## 1. Resultado e contexto de produto

Como criador autenticado, quero registrar uma tentação em rascunho local,
revisá-la, ver exatamente o que será mostrado ao convidado, publicar de modo
explícito e compartilhar um convite privado.

Esta task fecha o primeiro handoff da Entrega 1:
`rascunho local → revisão obrigatória → publicação privada → convite`.
Ela não transforma publicação em atalho, não coleta dados de convidados e não
antecipa decisão, reflexão, Reveal ou IA.

## 2. Pré-requisito de autenticação

A RPC existente `publish_dilemma` exige `auth.uid()` e um perfil que tenha
`display_name`, confirmação de maioridade e versões vigentes de Termos e Aviso
de Privacidade. O cliente mobile e o Google Sign-In estão implementados. A
Task 3B usa consentimentos internos versionados pela DEC-015; documentos
jurídicos aprovados e liberação externa continuam fora desse ambiente.

A [DEC-014](../DECISION_LOG.md#dec-014-autenticação-nativa-do-criador-por-google)
adotou Google Sign-In nativo para o criador. A implementação usa URL, chave
publicável Supabase e Client IDs públicos por `--dart-define`; Client Secret,
versões/cópia jurídica e Apple Sign In são configuração ou entregas separadas.
A criação do rascunho local não depende de rede; simular autenticação ou gravar
uma chave de serviço no app é proibido.

## 3. Escopo após o pré-requisito

- criar `apps/mobile` em Flutter e a fundação visual `Bib*` necessária para
  E1-S01 a E1-S05;
- armazenar localmente um único rascunho com item, preço em centavos, categoria,
  motivo, finalidade e pausa; recuperar após reinício como **Rascunho — não
  compartilhado**;
- validar os limites do PRD e exigir revisão e prévia antes de publicar;
- sincronizar, por RPC autenticada e estreita, o perfil mínimo de
  desenvolvimento com nome de exibição, maioridade e as versões internas
  `internal-demo-v1`, sem coletar data de nascimento ou usar metadados Google;
- chamar somente a RPC autenticada `publish_dilemma` com chave de idempotência;
- compartilhar o convite por folha nativa, sem exibir token/URL em tela ou logs;
- testar offline → reinício → revisão → publicação explícita e o contrato de
  publicação autenticada.

## 4. Não-escopo

- senha, perfil social, recuperação de conta ou qualquer conta de convidado;
- imagens, URLs de produto, razão de voto, comentários, notificações, Reveal,
  decisão, pontuação, feed, analytics, publicidade ou IA;
- revogação, exclusão e painel de agregados; permanecem slices próprias;
- deploy público do Web convidado, domínio, beta externo, chave de serviço,
  publicação em lojas ou envio de e-mail/SMS sem aprovação explícita.

## 5. Critérios de aceite

1. O rascunho permanece local, recupera após reinício e nunca é publicado por
   reconexão, reabertura ou ação implícita.
2. Campos inválidos impedem avançar, preservando o texto e o preço digitados.
3. A revisão e a prévia mostram todos os campos que o convidado verá; não há
   agregados, token, URL, prévia social específica ou dados de convidado.
4. Publicação exige sessão autenticada, perfil com maioridade/consentimentos e
   toque explícito após a prévia; usa idempotência para retry seguro.
5. O compartilhamento usa a folha nativa; cancelar não revoga nem publica outro
   dilema; a tela não expõe o token completo.
6. Componentes atendem contraste AA, semântica, targets de 48 px e escala de
   texto de 200%.

## 6. Estratégia de teste

| Camada | Cenários |
|---|---|
| Unitário | parse de BRL/centavos, limites de campos, máquina de estados e chave de idempotência persistida. |
| Repositório local | salvar, reiniciar, recuperar, editar e reconectar sem publicação. |
| Integração | cliente autenticado chama apenas `publish_dilemma`; resposta cria convite e retry repete o mesmo resultado. |
| Widget | banners, erros, ordem de foco, prévia fiel e CTA de publicação explícita. |
| E2E | offline → reinício → revisão → prévia → publicação → share cancelado; depois integra com o E2E Web existente. |
| RLS negativo | Task 3B restringe escrita direta de perfil e testa consentimentos; a suíte negativa de banco permanece obrigatória. |

## 7. Privacidade, risco e rollback

- Sem e-mail, telefone, token de convite, preço exato ou texto livre em logs ou
  analytics; não haverá analytics nesta task.
- O app recebe apenas a chave pública Supabase e a sessão do próprio criador;
  `service_role` nunca entra no cliente.
- A versão de Termos/Aviso e o método de Auth precisam ser definidos antes do
  cadastro/perfil. A autoafirmação +18 é necessária; data de nascimento não é.
- Em falha de publicação, manter o rascunho local e a mesma chave de
  idempotência; não executar retry automático em segundo plano.

## 8. Foco da revisão adversarial

Produto tenta publicar sem revisão, criar urgência ou introduzir IA/score.
Privacidade tenta expor token em UI/log/share e criar perfil sem consentimento.
QA corta a rede, mata o processo, troca o payload após timeout e cancela o
share sheet. Segurança tenta usar publicação sem sessão/perfil válido ou com
credencial privilegiada no bundle.
