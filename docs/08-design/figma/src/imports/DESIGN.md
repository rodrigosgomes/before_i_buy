# Design System — Playful Calm

## Visão

Este produto ajuda pessoas a desacelerar decisões de compra com apoio de amigos próximos. A experiência combina segurança emocional com a energia visual e a fluidez esperadas por quem usa redes sociais, Duolingo e produtos digitais gamificados.

O princípio central é **Playful Calm**: trocar pressão por curiosidade, companhia e descoberta. Calma não significa ausência de cor, movimento ou personalidade.

## Princípios

1. **Humano antes de funcional** — decisões aparecem como histórias pessoais, não registros financeiros.
2. **Social sem competição** — amigos oferecem perspectivas; não disputam precisão.
3. **Expressivo sem ruído** — formas, movimento e cores comunicam significado.
4. **Progresso sem pressão** — completar uma reflexão pode ser recompensador, mas nunca obrigatório.
5. **Autonomia explícita** — a decisão final pertence sempre à pessoa que iniciou o dilema.
6. **Privado por padrão** — métricas pessoais não se transformam em reputação pública.

## Linguagem visual

Use Material Design 3 Expressive como base, com superfícies arredondadas, hierarquia tipográfica forte, formas orgânicas, ícones amigáveis, sombras suaves e transições compartilhadas.

Evite repetição de cards idênticos. Alterne entre hero sections, carrosséis sociais, balões de fala, chips, ilustrações, barras orgânicas e bilhetes editoriais.

### Paleta

| Token | Hex | Uso |
|---|---:|---|
| Cloud Dancer | `#FAF9F6` | Canvas principal |
| Terracotta Clay | `#C56C51` | Marca e CTAs |
| River Slate | `#4F5D65` | Texto e estrutura |
| Muted Pebble | `#8E9AA1` | Texto secundário |
| Sandstone | `#EFECE6` | Superfícies neutras |
| Muted Teal | `#89AFA3` | Comprar, Sim, Alinhado |
| Muted Lavender | `#9C92A6` | Esperar, Talvez, Em aberto |
| Muted Sand | `#CBBCA9` | Deixar passar, Não, Diferente |
| Peach Glow | `#F2B49F` | Calor humano e conteúdo social |
| Soft Sky | `#AFC8D8` | Informações e descobertas |
| Butter Cream | `#E8D78C` | Recompensas e destaques discretos |

As cores semânticas possuem o mesmo peso moral. Nenhuma representa sucesso ou fracasso.

### Tipografia

- Display e títulos: Manrope, Nunito Sans ou Plus Jakarta Sans.
- Interface e corpo: Inter.
- Headlines: 24–32 px.
- Títulos de seção: 18–22 px.
- Corpo: 14–16 px.
- Labels: 12–14 px.
- Peso máximo: 700.

### Forma e elevação

- Cards principais: raio de 24–28 px.
- Cards compactos: raio de 18–20 px.
- Campos: raio de 14–16 px.
- Botões principais: raio de 18–22 px.
- Chips: formato capsule.
- Sombras: amplas, suaves e levemente coloridas.
- Evitar bordas decorativas em excesso.

### Espaçamento

- Grid mobile de quatro colunas.
- Margens laterais de 16 px.
- Unidade-base: 4 px.
- Ritmo vertical principal: 12 px.
- Separação entre seções: 20–32 px.
- Touch targets: mínimo de 44 × 44 px.

## Componentes

### Botão principal

- Superfície Terracotta Clay.
- Texto branco de alto contraste.
- Altura mínima de 52 px.
- Ícone opcional acompanhado de label.
- Feedback tátil e escala sutil ao pressionar.

### Opções semânticas

Comprar, Esperar e Deixar passar combinam cor, iconografia, texto e mudança de borda. A seleção aumenta levemente o componente, engrossa a borda, altera o ícone de outline para filled e mostra um label como “Meu palpite”.

### Card de dilema social

Contém avatar, nome, tempo relativo, fotografia do produto, motivo em balão de fala, contexto da pausa, participação dos amigos e CTA. Deve parecer uma publicação social, não uma tarefa.

### Avatares

- Fotografias ou ilustrações consistentes.
- Diversidade real de aparência.
- Tamanho mínimo individual de 28 px; ações usam 44 px.
- Sobreposição apenas quando houver texto complementar com quantidade.

### Métricas

- Sempre informar tamanho da amostra.
- Nunca tratar 100% como objetivo obrigatório.
- Usar “Alinhado”, “Diferente” e “Sem resposta”.
- Nunca usar “Correto”, “Incorreto”, “Vencedor” ou “Perdedor”.

### Estados offline

Mensagem recomendada:

> Salvo neste aparelho. Compartilharemos quando a conexão voltar.

Não usar alertas agressivos ou ameaçar perda de conteúdo.

## Movimento

- Duração: 200–400 ms.
- Celebrações: máximo de 1,2 segundo e sem loop.
- Cards selecionados: escala de 1.02 a 1.04.
- Usar shared-axis e container transforms entre telas relacionadas.
- Avatares entram com deslocamento orgânico discreto.
- Resultados só se animam depois da revelação.
- Respeitar `prefers-reduced-motion`.
- Evitar bounce excessivo, tremores e animações infinitas.

## Tom de voz

Escrever como uma pessoa próxima, clara e respeitosa.

Preferir:

- “Tudo bem querer isso.”
- “Vamos pensar com um pouco mais de espaço?”
- “Eles trouxeram perspectivas. Você traz a decisão.”
- “Foi diferente do que aconteceu — e tudo bem.”

Evitar:

- “Compra irresponsável”.
- “Você errou”.
- “Controle seus impulsos”.
- “Última chance”.
- “Tempo esgotando”.

## Gamificação ética

Permitido:

- Jornada em capítulos.
- Selos privados de participação.
- Pequenas celebrações.
- Coleção de aprendizados.
- Revelações graduais.
- Reconhecimento por apoiar amigos.

Proibido:

- XP, moedas e loot boxes.
- Rankings e ligas.
- Streaks punitivos.
- Comparação pública de precisão.
- Urgência artificial.
- Recompensas por gastar ou deixar de gastar.

## Acessibilidade

- Contraste WCAG 2.2 AA.
- Touch targets mínimos de 44 × 44 px.
- Textos essenciais com pelo menos 12 px.
- Cor nunca é o único indicador.
- Labels acessíveis em todos os controles.
- Navegação por teclado e leitor de tela.
- Estados de foco visíveis.
- Alternativa a gestos e animações.

## Critérios de aceite

- A interface parece social, humana e memorável.
- A home de amigos parece uma área de convites, não uma lista de tarefas.
- As telas possuem composições variadas.
- O produto não se parece com banco, planilha ou app terapêutico.
- A gamificação recompensa reflexão e presença.
- Não existem rankings, vencedores, perdedores ou streaks punitivos.
- Todas as métricas informam a amostra.
- A decisão final permanece com o dono do dilema.
- A experiência mantém personalidade com animações desativadas.
