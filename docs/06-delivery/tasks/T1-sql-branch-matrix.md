# Task 1 — matriz de cobertura SQL/RPC/RLS

Esta matriz é o gate mensurável para superfícies PostgreSQL, nas quais cobertura
de linha não representa autorização nem efeitos persistidos. O denominador é o
conjunto de ramos protegidos introduzidos ou afetados pela Task 1. Um ramo conta
como exercitado somente quando pgTAP ou o teste de concorrência executa o banco
real e verifica retorno, grant ou efeito persistido.

**Resultado local:** 55 de 59 ramos exercitados (`93,2%`). Nenhuma negação de
risco P0/P1 foi omitida. Os quatro ramos não exercitados são falhas operacionais
de bootstrap ou validações defensivas internas, e não caminhos autorizativos de
cliente.

| ID | Ramo protegido | Evidência | Estado |
|---|---|---|---|
| P01 | publicação sem autenticação é negada | `010-rls-negative-access_test.sql` | exercitado |
| P02 | perfil sem maioridade confirmada é negado | `020-guest-vote-rpc_test.sql` | exercitado |
| P03 | chave de idempotência ausente é negada | `020-guest-vote-rpc_test.sql` | exercitado |
| P04 | janela de pausa fora da allowlist é negada | `010-rls-negative-access_test.sql` | exercitado |
| P05 | primeira publicação cria um único dilema | `020-guest-vote-rpc_test.sql` | exercitado |
| P06 | retry com mesma chave repete dilema e token | `020-guest-vote-rpc_test.sql` | exercitado |
| P07 | mesma chave com payload diferente falha | `020-guest-vote-rpc_test.sql` | exercitado |
| P08 | somente SHA-256 do token é gravado | `020-guest-vote-rpc_test.sql` | exercitado |
| P09 | publisher legado com token do cliente não executa | `020-guest-vote-rpc_test.sql` | exercitado |
| P10 | `authenticated` não insere dilema diretamente | `020-guest-vote-rpc_test.sql` | exercitado |
| P11 | `authenticated` não altera token/estado diretamente | `020-guest-vote-rpc_test.sql` | exercitado |
| P12 | cliente não lê a chave protegida pelo Vault | `020-guest-vote-rpc_test.sql` | exercitado |
| P13 | unicidade por dono e chave existe | `020-guest-vote-rpc_test.sql` | exercitado |
| P14 | chave Vault ausente/corrompida falha fechada | guarda interna da migration | não exercitado |
| P15 | migration aborta se encontrar chave legada | preflight da migration | não exercitado |
| R01 | aberturas 1–30 são aceitas | `020-guest-vote-rpc_test.sql` | exercitado |
| R02 | abertura 31 é limitada | `020-guest-vote-rpc_test.sql` | exercitado |
| R03 | votos 1–10 são aceitos pelo contador | `020-guest-vote-rpc_test.sql` | exercitado |
| R04 | voto 11 é limitado | `020-guest-vote-rpc_test.sql` | exercitado |
| R05 | escopo desconhecido falha fechado | `020-guest-vote-rpc_test.sql` | exercitado |
| R06 | hash de sujeito malformado falha fechado | guarda interna da RPC | não exercitado |
| R07 | expiração de sujeito no passado falha fechada | guarda interna da RPC | não exercitado |
| R08 | TTL fica em no máximo 60 segundos | `020-guest-vote-rpc_test.sql` | exercitado |
| R09 | contador pseudônimo expirado é removido | `020-guest-vote-rpc_test.sql` | exercitado |
| O01 | parâmetros de abertura malformados são negados | `010-rls-negative-access_test.sql` | exercitado |
| O02 | token desconhecido não retorna projeção | `020-guest-vote-rpc_test.sql` | exercitado |
| O03 | token desconhecido de formato válido é contado | `020-guest-vote-rpc_test.sql` | exercitado |
| O04 | convite ativo cria sessão restrita | `010` e `020` pgTAP | exercitado |
| O05 | convite revogado não abre | `010-rls-negative-access_test.sql` | exercitado |
| O06 | convite expirado não abre nem revela existência | `010-rls-negative-access_test.sql` | exercitado |
| O07 | estado inválido não abre | `010-rls-negative-access_test.sql` | exercitado |
| O08 | repetição segura não duplica sessão | `010-rls-negative-access_test.sql` | exercitado |
| O09 | segredo reutilizado em outro dilema é negado | `010-rls-negative-access_test.sql` | exercitado |
| O10 | revogação concorrente vence antes da sessão | `guest-session-concurrency.test.mjs` | exercitado |
| V01 | parâmetros de voto malformados são negados | `020-guest-vote-rpc_test.sql` | exercitado |
| V02 | sessão desconhecida de formato válido é contada | `020-guest-vote-rpc_test.sql` | exercitado |
| V03 | sessão não atravessa dilemas | `020-guest-vote-rpc_test.sql` | exercitado |
| V04 | segredo incorreto é negado | `020-guest-vote-rpc_test.sql` | exercitado |
| V05 | sessão expirada é negada | `020-guest-vote-rpc_test.sql` | exercitado |
| V06 | sessão revogada é negada | `020-guest-vote-rpc_test.sql` | exercitado |
| V07 | convite revogado é negado | `020-guest-vote-rpc_test.sql` | exercitado |
| V08 | estado diferente de coleta é negado | `020-guest-vote-rpc_test.sql` | exercitado |
| V09 | prazo alcançado é negado | `020-guest-vote-rpc_test.sql` | exercitado |
| V10 | primeiro voto é persistido | `020-guest-vote-rpc_test.sql` | exercitado |
| V11 | mesma previsão é idempotente | `020-guest-vote-rpc_test.sql` | exercitado |
| V12 | previsão diferente substitui a anterior | `020-guest-vote-rpc_test.sql` | exercitado |
| V13 | agregados somam o total persistido | `020-guest-vote-rpc_test.sql` | exercitado |
| V14 | uma sessão mantém uma participação e um voto | `020-guest-vote-rpc_test.sql` | exercitado |
| V15 | valor fora do enum é rejeitado | `020-guest-vote-rpc_test.sql` | exercitado |
| V16 | escolhas simultâneas não duplicam voto | `guest-session-concurrency.test.mjs` | exercitado |
| V17 | revogação concorrente impede persistência | `guest-session-concurrency.test.mjs` | exercitado |
| V18 | expiração enquanto aguarda lock impede persistência | `guest-session-concurrency.test.mjs` | exercitado |
| D01 | participação convidada exige sessão real do dilema | `020-guest-vote-rpc_test.sql` | exercitado |
| D02 | exatamente uma forma de identidade é exigida | `020-guest-vote-rpc_test.sql` | exercitado |
| D03 | apagar sessão remove participação e voto | `020-guest-vote-rpc_test.sql` | exercitado |
| D04 | apagar perfil remove participação autenticada | `020-guest-vote-rpc_test.sql` | exercitado |
| D05 | `anon` não tem leitura ou DML direto | `010` e `020` pgTAP | exercitado |
| D06 | RPC devolve somente a allowlist pós-voto | `020-guest-vote-rpc_test.sql` | exercitado |
| D07 | sessão expirada apaga o hash e preserva a âncora do voto | `020-guest-vote-rpc_test.sql` | exercitado |

## Regra do gate

A task falha se a razão cair abaixo de 80% ou se qualquer ramo de autenticação,
escopo entre dilemas, revogação, prazo, DML direto, segredo, agregado pré-voto ou
idempotência ficar sem teste. Ramos operacionais não exercitados devem permanecer
listados; eles não podem ser retirados do denominador para melhorar o número.
