# Protocolo de usabilidade interna 3+3 — Entrega 1

## Participantes e dados

- três criadores e três convidados da equipe ou autorizados internamente;
- participantes identificados no relatório somente como `C1`–`C3` e
  `G1`–`G3`;
- dilemas e nomes de exibição fictícios;
- links enviados individualmente e removidos após a sessão;
- registrar somente duração, conclusão, erros e observações sem conteúdo.

## Roteiro do criador

1. Iniciar na entrada do formulário, com autenticação e onboarding já prontos.
2. Criar um dilema fictício, revisar e publicar.
3. Encerrar o cronômetro quando a confirmação de publicação aparecer.
4. Abrir a folha nativa de compartilhamento sem enviar o link a terceiros.
5. Após o voto do convidado, atualizar o painel e confirmar os agregados.
6. Alternar entre revogar e excluir nos casos distribuídos entre participantes.

## Roteiro do convidado

1. Iniciar ao abrir o link em navegador móvel suportado.
2. Confirmar que não há cadastro e que agregados ainda não aparecem.
3. Escolher e enviar um voto; encerrar o cronômetro na confirmação.
4. Abrir os agregados e alterar o voto.
5. Em um link revogado ou vencido, confirmar a resposta genérica.

## Verificação de acessibilidade no staging

- completar o voto somente com teclado e observar foco visível;
- confirmar anúncio dos títulos, opções, erros e confirmação por leitor de tela;
- verificar contraste dos estados interativos;
- repetir em 320 px e com texto a 200%, sem perda de conteúdo ou ação;
- confirmar ausência de item, preço, criador e token no HTML inicial, metatags,
  histórico compartilhável e cabeçalho `Referer`.

## Registro anonimizado

| Participante | Papel | Duração (s) | Concluiu | Erros | Observação sem conteúdo |
|---|---|---:|---|---:|---|
| C1 | criador |  |  |  |  |
| C2 | criador |  |  |  |  |
| C3 | criador |  |  |  |  |
| G1 | convidado |  |  |  |  |
| G2 | convidado |  |  |  |  |
| G3 | convidado |  |  |  |  |

Calcular a mediana separadamente por papel. A versão somente passa com criação
abaixo de 120 segundos, voto abaixo de 20 segundos e nenhuma falha crítica de
privacidade, autorização ou acessibilidade. Uma amostra afetada deve ser
repetida após correção na mesma versão.
