# Prompt de Produto — Protótipo Social de Decisões de Compra

## Objetivo

Crie um protótipo mobile navegável com **9 telas**, dentro de um único viewport de **393 × 852 px**, equivalente ao iPhone 15 padrão.

O aplicativo ajuda pessoas a desacelerar decisões de compra, pedir perspectivas a amigos próximos e aprender com escolhas anteriores. A experiência não pode parecer clínica, burocrática, financeira ou excessivamente minimalista.

O público utiliza redes sociais, Duolingo e aplicativos gamificados. A interface precisa transmitir humanidade, personalidade, movimento e recompensa visual sem recorrer a ansiedade, competição ou manipulação.

## 1. Direção criativa

Desenvolva uma experiência **Playful Calm**: humana, social, expressiva e acolhedora.

Combine:

- Material Design 3 Expressive.
- A clareza e a recompensa visual de aplicativos como Duolingo.
- A familiaridade social de Instagram, BeReal e aplicativos de mensagens.
- Ilustrações editoriais contemporâneas.
- Gamificação gentil, privada e não competitiva.
- Microinterações que transmitam progresso, companhia e descoberta.
- Conteúdo conversacional, evitando linguagem de sistema.

O aplicativo não deve eliminar energia para parecer calmo. Deve trocar ansiedade por curiosidade, companhia e sensação de progresso.

### Não produzir

- Telas excessivamente bege, vazias ou monocromáticas.
- Layout editorial estático.
- Cards genéricos repetidos verticalmente.
- Interface corporativa, bancária ou terapêutica.
- Ícones minúsculos e sem personalidade.
- Excesso de texto explicativo.
- Emojis como substitutos de direção de arte.
- Rankings, ligas ou comparação pública.
- Streaks punitivos ou pontuações de consumo.
- Confetes exagerados, moedas, troféus ou estética de cassino.
- Vermelho e verde saturados como certo e errado.
- Contadores regressivos, urgência artificial ou culpa.

## 2. Sistema visual

### Material Design 3 Expressive

- Grandes superfícies arredondadas.
- Cantos entre 18 e 28 px.
- Botões volumosos e confortáveis.
- Hierarquia tipográfica marcante.
- Formas orgânicas e assimétricas.
- Elevação suave e sombras levemente coloridas.
- Bottom sheets e transições compartilhadas.
- Ícones arredondados com peso consistente.
- Estados selecionados claramente táteis.
- Variação de composição entre telas.

Evite empilhar componentes idênticos. Alterne hero sections, carrosséis, balões de fala, chips, ilustrações, barras e bilhetes editoriais.

### Paleta

- Cloud Dancer `#FAF9F6` — canvas.
- Terracotta Clay `#C56C51` — marca e CTAs.
- River Slate `#4F5D65` — texto e estrutura.
- Muted Pebble `#8E9AA1` — conteúdo secundário.
- Sandstone `#EFECE6` — superfícies neutras.
- Muted Teal `#89AFA3` — Comprar, Sim, Alinhado.
- Muted Lavender `#9C92A6` — Esperar, Talvez, Em aberto.
- Muted Sand `#CBBCA9` — Deixar passar, Não, Diferente.
- Peach Glow `#F2B49F` — calor social.
- Soft Sky `#AFC8D8` — informação e descoberta.
- Butter Cream `#E8D78C` — recompensa discreta.

As três cores semânticas possuem o mesmo peso moral. Use gradientes suaves, nunca neon.

### Tipografia

- Títulos: Manrope, Nunito Sans ou Plus Jakarta Sans.
- Interface: Inter.
- Headlines: 24–32 px.
- Títulos de seção: 18–22 px.
- Corpo: 14–16 px.
- Labels: 12–14 px.
- Peso máximo: 700.

### Grid e acessibilidade

- Grid mobile de quatro colunas.
- Margens laterais de 16 px.
- Espaçamento-base de 12 px.
- Touch targets mínimos de 44 × 44 px.
- Contraste WCAG 2.2 AA.
- Textos essenciais com pelo menos 12 px.
- Navegação por teclado e leitores de tela.
- Suporte a `prefers-reduced-motion`.

Cor nunca pode ser o único indicador. Todo estado combina cor, ícone, texto atualizado e mudança de borda ou superfície.

### Fotografia e ilustração

- Produtos reais recortados sobre fundos suaves.
- Sombras naturais e levemente coloridas.
- Rabiscos, estrelas e formas desenhadas à mão.
- Avatares expressivos e diversos.
- Ilustrações de foco, espera, reflexão e descoberta.
- Stickers vetoriais refinados, sem infantilização.

## 3. Gamificação gentil

### Permitido

- Jornada visual em capítulos.
- Progressão: Convites → Desejo → Pausa → Perspectivas → Escolha → Reflexão → Aprendizado.
- Animações de confirmação.
- Cards responsivos à seleção.
- Revelações graduais.
- Coleção privada de aprendizados.
- Personagem-guia discreto.
- Incentivo baseado em participação.
- Selos “Palpite enviado”, “Pausa criada”, “Reflexão concluída” e “Novo padrão percebido”.
- Celebrações suaves por apoiar um amigo.

### Proibido

- XP, moedas e loot boxes.
- Rankings e ligas.
- Streaks punitivos.
- “Você ganhou” ou “Você perdeu”.
- Precisão como valor moral.
- Recompensas por gastar ou evitar gastar.
- Notificações culpabilizadoras.

## 4. Telas

### Tela 1 — Início dos amigos

**Objetivo:** transformar palpites pendentes em convites sociais leves, não em tarefas.

#### Header

- Saudação “Oi, Rafa”.
- Subtexto “Algumas pessoas querem pensar com você.”
- Avatar de 44 × 44 px.
- Notificações sem badge agressivo.

#### Hero social

- Ilustração com três avatares e formas orgânicas.
- Headline “3 amigos querem seu olhar.”
- Texto “Não é sobre decidir por eles. É sobre mostrar um ângulo que talvez ainda não tenham visto.”
- Mostrar “3 palpites para dar” como informação, não cobrança.

#### Dilemas pendentes

Apresentar como carrossel ou pilha de publicações sociais.

**Lu:** avatar, “Lu pediu seu palpite”, “há 2 h”, fotografia do headphone, nome, preço, motivo “Quero ter mais foco no trabalho e nas viagens”, chip “Pausa de 3 dias”, avatares e “2 amigos já responderam”. CTA “Dar meu palpite” e ação “Ver depois”.

**Caio:** “Tênis para corrida”, motivo “Quero voltar a treinar sem desconforto”, CTA “Pensar junto”.

**Marina:** “Câmera instantânea”, motivo “Quero registrar melhor as viagens com meus pais”, CTA “Pensar junto”.

#### Presença social

- “Você ajudou 4 amigos a pensar este mês.”
- “Nenhuma pontuação. Só conversas que importam.”

Celebrar presença, não precisão.

#### Estado vazio

- Ilustração de uma caixa de entrada descansando.
- “Tudo tranquilo por aqui.”
- “Quando alguém quiser seu olhar, o convite aparece aqui.”
- Link “Ver reflexões anteriores”.

Não usar “Parabéns, você zerou tudo”.

### Tela 2 — Minha Tentação

**Objetivo:** externalizar o desejo em um espaço acolhedor e visualmente rico.

- Header com marca orgânica e “Capítulo 1 de 5”.
- Fotografia editorial do headphone sobre shape terracota ou pêssego.
- Sticker “Entrou no radar”.
- Headline “Tudo bem querer isso.”
- Texto “Vamos entender essa vontade antes de decidir?”
- Produto “Headphone Noise-Cancelling” e preço “R$ 2.400,00”.
- Pergunta “Por que você quer comprar isso agora?”
- Resposta “Ter mais foco no trabalho e viagens.”
- Chips “Facilitar minha rotina”, “Me sentir melhor”, “Resolver um problema” e “Só estou com vontade”.
- Pausas de 24 horas, 3 dias e 7 dias em cards táteis.
- Seleção com escala, borda, ícone e texto de confirmação.
- Avatares e “Quem conhece você pode ajudar a enxergar outros ângulos.”
- Privacidade “Apenas amigos próximos convidados.”
- CTA “Criar minha pausa”.
- Ação “Ver como meus amigos receberão”.

### Tela 3 — Palpite do amigo

**Objetivo:** produzir previsão empática sem conselho direto ou ancoragem.

- Avatar e “Lu convidou você para pensar junto”.
- Produto compacto e motivo em balão de fala.
- Pergunta “Daqui a 30 dias, como você acha que a Lu vai se sentir?”
- Texto “Não tente decidir por ela. Imagine como essa escolha pode se encaixar na vida dela.”
- Comprar — sacola; “Ela vai valorizar a escolha”.
- Esperar — ampulheta; “Talvez ainda seja cedo”.
- Deixar passar — caminho alternativo; “Ela ficará bem sem isso”.
- Cada opção possui forma e microanimação próprias.
- Seleção expande, recebe borda de 3 px, ícone filled, label “Meu palpite” e texto atualizado.
- Campo “Quer deixar um recado para a Lu?”
- Placeholder “Escreva como você falaria com ela...”
- CTA inicialmente bloqueado “Enviar meu palpite”.
- Ocultar resultados até o envio.
- Confirmação “Palpite enviado. Agora é só dar espaço para a Lu decidir.”
- Ações “Voltar aos convites” e “Fechar por agora”.

### Tela 4 — Pausa para clareza

**Objetivo:** transformar espera em espaço, não pressão.

- “Capítulo 2 · Pausa para clareza”.
- Produto em card compacto.
- Paisagem visual com órbita ou caminho ilustrado.
- Pequeno objeto ou personagem percorrendo o caminho.
- “A vontade está descansando.”
- “Faltam 2 dias para revisitar essa escolha.”
- “Sua pausa termina sexta-feira às 18:00.”
- Avatares ao redor da órbita.
- “4 pessoas que conhecem você já deixaram perspectivas.”
- “Você não precisa decidir nada agora.”
- “A escolha final continua sendo 100% sua.”
- CTA “Ver perspectivas”.

Nunca usar “tempo acabando”, “última chance” ou “somente hoje”.

### Tela 5 — A escolha continua sendo sua

**Objetivo:** revelar perspectivas sem entregar a decisão ao grupo.

- “Capítulo 3 · Hora de revisitar”.
- “Seus amigos enxergaram caminhos diferentes.”
- Barra orgânica: 25% Comprar, 50% Esperar, 25% Deixar passar.
- Parear cores com ícones, textos e padrões.
- Comentários como balões com avatar.
- “Acho excelente para seu foco, e você viaja bastante.”
- “Talvez você ache um modelo mais barato se esperar.”
- “Eles trouxeram perspectivas. Você traz a decisão.”
- Pergunta “O que aconteceu de verdade?”
- Opções: item original, alternativa, deixar passar, indisponível ou ainda decidindo.
- CTA “Registrar minha escolha”.

### Tela 6 — Reflexão posterior

**Objetivo:** comparar expectativa e realidade de forma gentil.

- Visual de mensagem do Futuro Eu ou envelope abrindo.
- “Uma mensagem de 30 dias atrás.”
- Bilhete “Ter mais foco no trabalho e viagens.”
- “Você ainda está com o produto?”
- Opções “Sim, mantive” e “Não, devolvi”.
- Se devolvido, adaptar a lógica de satisfação.
- “Você faria a mesma escolha novamente?”
- Respostas “Sim, faria de novo”, “Talvez” e “Não faria novamente”.
- Cada resposta tem ícone, texto e descrição.
- Campo “O que você gostaria de lembrar na próxima vez?”
- CTA “Descobrir o que mudou”.

### Tela 7 — Revelação social

**Objetivo:** fechar o ciclo sem vencedores ou perdedores.

- Animação curta de formas orgânicas.
- “A história chegou a um desfecho.”
- “Lu comprou o headphone.”
- “Faria a mesma escolha novamente.”
- Repetir a barra agregada.
- “Você imaginou que esperar seria melhor.”
- “Foi diferente do que aconteceu — e tudo bem.”
- Nunca usar “errado”, “perdeu” ou “falhou”.
- Depoimento de Lu: “Eles realmente salvam meu foco no avião e no escritório.”
- CTA “Ver como meus palpites estão evoluindo”.

### Tela 8 — Minha sensibilidade

**Objetivo:** promover evolução privada, não status.

- “Você está aprendendo a enxergar com os olhos dos outros.”
- 7 alinhados, 3 diferentes e 2 sem resposta.
- Indicador “58% de alinhamento”.
- Não tratar 100% como objetivo.
- “Baseado nas últimas 10 previsões resolvidas.”
- Tecnologia — 4 de 6.
- Estilo — 1 de 3.
- Ícones ilustrados e barras orgânicas.
- “Isto é um padrão para observar, não uma nota sobre você.”
- CTA “Ver o que estou aprendendo”.

### Tela 9 — O que meu Futuro Eu aprendeu

**Objetivo:** apresentar padrões pessoais sem vergonha financeira.

- Tela mais rica e recompensadora.
- Ilustração de espelho, janela ou caderno.
- “Em 8 de 10 decisões, você faria a mesma escolha novamente.”
- “Histórico dos últimos 12 meses.”
- Cards privados:
  - “Viagens costumam trazer satisfação duradoura — 3 de 3.”
  - “Esperar mudou sua decisão em 4 dilemas.”
  - “R$ 1.200 foram preservados sem abrir mão do que importa.”
- Filtro da Ilusão privado com cadeado:
  - Sua expectativa: 58%.
  - Palpite dos amigos: 50%.
  - Sua realidade: 80%.
- “Você costuma subestimar sua satisfação futura.”
- “Este padrão pode mudar conforme novas decisões forem registradas.”
- CTA “Revisitar meus dilemas”.

## 5. Movimento

- Animações de 200–400 ms com easing suave.
- Shared-axis entre capítulos.
- Produto se transforma entre telas relacionadas.
- Cards selecionados usam escala de 1.02 a 1.04.
- Ícones mudam de outline para filled.
- Avatares entram organicamente.
- Barras só crescem após a revelação.
- Bilhete do Futuro Eu abre como carta.
- Celebrações duram no máximo 1,2 segundo e não repetem.
- Sugerir haptic feedback.
- Usar skeletons suaves.
- Respeitar `prefers-reduced-motion`.

Não usar bounce excessivo ou animações infinitas.

## 6. Fluxo navegável

```text
[Tela 1 — Início dos amigos]
   ├── Dar meu palpite → [Tela 3]
   ├── Pensar junto → atualizar conteúdo da [Tela 3]
   └── Ver depois → reorganizar card sem punição

[Tela 2 — Minha Tentação]
   ├── Criar minha pausa → [Tela 4]
   └── Ver como amigos receberão → [Tela 3]

[Tela 3 — Palpite do amigo]
   ├── Selecionar → atualizar texto, ícone, borda e superfície
   ├── Enviar → confirmação
   └── Voltar aos convites → [Tela 1]

[Tela 4 — Pausa] → Ver perspectivas → [Tela 5]
[Tela 5 — Escolha] → Registrar → atraso simulado → [Tela 6]
[Tela 6 — Reflexão] → Descobrir o que mudou → [Tela 7]
[Tela 7 — Revelação] → Ver evolução → [Tela 8]
[Tela 8 — Sensibilidade] → Ver aprendizados → [Tela 9]
[Tela 9 — Futuro Eu] → Revisitar dilemas → Histórico
```

Use Smart Animate de aproximadamente 300 ms. Inclua um mapa discreto para abrir qualquer tela durante a apresentação; esse mapa não pertence ao produto final.

## 7. Estados essenciais

Desenhe variantes para:

- Palpites pendentes e nenhum palpite pendente.
- Dilema adiado com “Ver depois”.
- Palpite vazio, selecionado e enviado.
- Pausa ativa e concluída.
- Produto mantido e devolvido.
- Decisão ainda aberta.
- Conteúdo offline salvo localmente.
- Erro de conexão sem perda de dados.

Mensagem offline:

> Salvo neste aparelho. Compartilharemos quando a conexão voltar.

## 8. Auditoria final

- [ ] O aplicativo parece social, humano e desejável.
- [ ] A home dos amigos parece uma área de convites, não tarefas.
- [ ] Há variedade real entre as nove telas.
- [ ] O produto não parece banco ou formulário financeiro.
- [ ] A gamificação recompensa reflexão e presença.
- [ ] Não há rankings, vencedores, perdedores ou streaks punitivos.
- [ ] Não há urgência artificial ou linguagem de culpa.
- [ ] Não há cores de trading ou estética de cassino.
- [ ] Todo estado usa cor, texto, borda e iconografia.
- [ ] Todas as métricas informam a amostra.
- [ ] “4 de 6”, “1 de 3”, “3 de 3”, “8 de 10” e “últimas 10 previsões” aparecem explicitamente.
- [ ] Agregados ficam ocultos até o amigo enviar o palpite.
- [ ] A decisão final pertence ao dono do dilema.
- [ ] A interface mantém personalidade sem animação.
- [ ] Nenhum texto usa “Somente hoje”, “Última chance” ou “Tempo esgotando”.
- [ ] Todos os touch targets possuem pelo menos 44 × 44 px.

O resultado deve ser caloroso, memorável e compartilhável: uma experiência que torna a pausa interessante e social, em vez de parecer uma punição.
