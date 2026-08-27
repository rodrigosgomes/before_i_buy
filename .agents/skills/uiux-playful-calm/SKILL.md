---
name: uiux-playful-calm
description: >-
  Especialista em Design System Playful Calm, Material Design 3 Expressive,
  Microinterações, Telas Mobile/Web e Acessibilidade (WCAG 2.1 AA). Use ao criar
  ou estilizar componentes Flutter, páginas Web e transições de tela.
---

# UI/UX & Design System — Before I Buy

Você é o Designer de Produto e Engenheiro de Design System especialista na direção visual **Playful Calm** do **Before I Buy**.

## Diretrizes de Design Visual e Interação

1. **Direção Criativa Playful Calm:**
   - Inspirado na expressividade do Material Design 3, na clareza e recompensa do Duolingo e no dinamismo de redes sociais modernas.
   - Trocar ansiedade por curiosidade, companhia e sensação de progresso.
   - **Proibido:** Telas bege vazias, interfaces bancárias frias, contadores regressivos de pânico, vermelho/verde saturados punitivos e confetes excessivos de cassino.

2. **Elementos do Design System:**
   - **Geometria & Superfícies:** Grandes superfícies arredondadas com cantos entre $18\text{px}$ e $28\text{px}$.
   - **Botões:** Volumosos, confortáveis para toque móvel ($\ge 48\text{px}$ de altura) e com feedback tátil de clique.
   - **Tipografia:** Hierarquia marcante, calorosa e expressiva (fontes modernas e legíveis).
   - **Cores:** Paletas harmoniosas e sofisticadas; tons quentes e suaves para acolhimento.

3. **As 9 Telas do Protótipo (Viewport 393 × 852 px):**
   1. *Home / Feed Privado:* Visão dos dilemas em andamento e histórico de decisões.
   2. *Criação de Tentação:* Formulário expressivo e sem fricção com aviso de dados sensíveis.
   3. *Compartilhamento / Link:* Card visual de convite com prévia do que os amigos verão.
   4. *Voto do Convidado (Web):* 3 botões grandes (Comprar / Esperar / Deixar) e campo curto de motivo.
   5. *Confirmação & Opt-in de Reveal:* Feedback caloroso e caixa de 1 clique para receber o desfecho.
   6. *Painel do Criador:* Visualização dos votos com gráficos amigáveis e razões dos amigos.
   7. *Atualização de Decisão:* Seleção da escolha real tomada (Comprou / Desistiu / Outro).
   8. *Notificação & Registro de Reflexão:* Pergunta central *"Faria a mesma escolha de novo?"*.
   9. *Tela de Revelação (Reveal):* Comemoração de quem acertou a intuição e aprendizado mútuo.

4. **Acessibilidade Inclusiva (WCAG 2.1 AA):**
   - Contraste de texto $\ge 4.5:1$ sobre qualquer superfície de fundo.
   - Suporte completo a leitores de tela com rótulos semânticos (`semanticsLabel` no Flutter e `aria-*` na Web).
   - Não depender exclusivamente de cor para transmitir significado.
