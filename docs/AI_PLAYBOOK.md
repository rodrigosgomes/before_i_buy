# Playbook de Engenharia & Desenvolvimento Assistido por IA
**Projeto:** Before I Buy  
**Versão:** 1.0  
**Público-Alvo:** Agentes de IA (LLMs) e Engenheiros de Software  

---

## 1. Visão do Produto & Wedge Central

O **Before I Buy** é um jogo social privado de tomada de decisão para compras discricionárias. O objetivo central é ajudar adultos a interromperem impulsos de compra imediatos, coletarem previsões de amigos de confiança e fecharem o ciclo de aprendizagem através de uma reflexão posterior.

### O Loop Fechado (Closed Loop)
Toda funcionalidade no repositório deve servir para viabilizar e acelerar este ciclo:

$$\text{Tentação (Dilema)} \to \text{Previsão dos Amigos} \to \text{Pausa} \to \text{Decisão} \to \text{Reflexão Tardia} \to \text{Revelação (Reveal)} \to \text{Autoconhecimento}$$

### Guardrails & Anti-Goals (O que NUNCA fazer)
- ❌ **Sem Feed Público ou Busca:** Todos os dilemas são privados e não indexáveis (`unlisted`).
- ❌ **Sem IA Preditiva no MVP:** A inteligência central é a intuição e perspectiva social humana.
- ❌ **Sem Conexão Bancária / Open Finance:** Não é um gerenciador financeiro nem planilha de gastos.
- ❌ **Sem Gamificação Tóxica / Culpa:** Proibidos rankings públicos, streaks punitivos ou shaming financeiro.
- ❌ **Sem Previews de Link Expositivos:** OpenGraph no WhatsApp/Telegram é sempre 100% neutro (nunca expor nome do item, valor ou foto na metatag).

---

## 2. Stack Tecnológica & Arquitetura

```text
┌────────────────────────────────────────────────────────┐
│                   CLIENT SURFACES                      │
├───────────────────────────┬────────────────────────────┤
│   App Mobile (Flutter)    │   Web Convidado (Next.js)  │
│  - Criador & Autenticado  │  - Voto em 15s sem login   │
│  - Rascunho Offline Local │  - Bundle ultraleve <150KB │
│  - Material 3 Expressive  │  - SSR / Carregamento Rápido│
└─────────────┬─────────────┴──────────────┬─────────────┘
              │                            │
              ▼                            ▼
┌────────────────────────────────────────────────────────┐
│             BACKEND & BANCO (Supabase/Postgres)        │
├────────────────────────────────────────────────────────┤
│  - PostgreSQL 15+ com RLS Estrita (Deny-by-Default)    │
│  - Edge Functions (Mutação atômica & Token exchange)   │
│  - pg_cron (Agendamento de reflexões de 7d e 30d)      │
│  - Storage Privado com RLS (Uploads com EXIF removido) │
└────────────────────────────────────────────────────────┘
```

---

## 3. Padrões de Engenharia para IAs

Ao trabalhar neste repositório, qualquer IA deve seguir estritamente os 4 pilares:

### 3.1. Schema-First & Contract-First
* **A Verdade Absoluta:** O Schema SQL do PostgreSQL (`/backend/supabase/migrations/`) e os tipos TypeScript/Dart compartilhados são a fonte da verdade.
* **Nunca invente propriedades:** Antes de criar ou modificar telas/APIs, consulte as tabelas e enums existentes.

### 3.2. Vertical Slice Architecture (Arquitetura por Funcionalidade)
* Organize o código por funcionalidade (*features*), agrupando telas, controladores e estado no mesmo diretório:
  ```
  lib/features/dilemma_create/
    ├── dilemma_create_screen.dart
    ├── dilemma_create_controller.dart
    └── dilemma_local_storage.dart
  ```
* **Vantagem para IA:** Mantém o raio de impacto (*blast radius*) pequeno e evita carregar dezenas de arquivos no contexto.

### 3.3. Simplicidade Cirúrgica (Princípio Ponytail & YAGNI)
1. *Não crie abstrações especulativas:* Nada de fábricas genéricas para casos de uso únicos.
2. *Prefira recursos nativos:* Use constraints de banco antes de validações em código; use estilos de Material 3 antes de bibliotecas de animação pesadas.
3. *Edições cirúrgicas:* Modifique apenas as linhas necessárias. Não refatore código adjacente que não faça parte da tarefa.

### 3.4. TDD & Quality Gate Obrigatório ($\ge 80\%$ Cobertura)
* **Regra Inegociável:** Todo PR/tarefa deve manter ou aumentar a cobertura de testes automatizados para $\ge 80\%$.
* **Frameworks Padronizados:**
  - **Mobile:** `flutter_test` + `mocktail` (Unit/Widget) e `integration_test` (E2E).
  - **Web:** `Vitest` + `@testing-library/react` + `Playwright` (E2E).
  - **Backend:** `pgTAP` / `Vitest` com Supabase Test Helpers para testes de RLS.

---

## 4. Framework de Security and Privacy by Design (SPbD)

### 4.1. Row Level Security (RLS) Deny-by-Default
* Toda tabela SQL **deve** ter `ENABLE ROW LEVEL SECURITY`.
* **Testes Negativos Obrigatórios:** Antes de commitar qualquer tabela, criar testes que comprovem:
  1. Anônimo sem token $\to$ Bloqueado (0 linhas / 403).
  2. Anônimo com token de outro dilema $\to$ Bloqueado.
  3. Usuário autenticado tentando editar dilema alheio $\to$ Bloqueado.
  4. Votante tentando ler auto-previsão privada do criador $\to$ Bloqueado.

### 4.2. Tratamento Criptográfico de Tokens
* **Geração:** Tokens de convite com $\ge 128$ bits de entropia gerados no cliente/edge.
* **Persistência:** O banco armazena **apenas o hash SHA-256** (`invite_token_hash`), nunca o token original.
* **Sessão do Convidado:** Token trocado por sessão efêmera restrita a 1 único `dilemma_id`.

### 4.3. Conformidade LGPD & Ciclo de Vida dos Dados
* **Exclusão de Conta:** Deleção física (*hard delete*) em cascata de dados e mídias no Storage em $\le 48$ horas.
* **Dados de Convidados:** E-mails/push coletados para notificação do *Reveal* possuem opt-in isolado e são excluídos automaticamente 30 dias após o envio do desfecho.

---

## 5. Máquinas de Estado & Regras de Negócio

### 5.1. Ciclo de Vida do Dilema
```
[draft] (Local offline / Unpublished)
   │ (Publicação explícita com token)
   ▼
[published] (Votação aberta aos amigos: 24h / 72h / 7d)
   │ (Criador atualiza a decisão real)
   ▼
[decided] (Decisão registrada: bought_original, bought_alt, skipped, unavailable)
   │ (pg_cron agenda reflexão: 7d perecível / 30d durável)
   ▼
[reflected] (Criador responde: "Faria a mesma escolha de novo? Sim/Dúvida/Não")
   │ (Notificação do Reveal enviada aos votantes com opt-in)
   ▼
[closed] (Visualização liberada + cálculo de intuição/acertos)
```

### 5.2. Regras de Pontuação do Reveal (Mecânica Justa)
* **Previsão Correta:**
  - Votou `Comprar` $\to$ Criador comprou $\to$ Reflexão tardia foi `Sim`.
  - Votou `Deixar pra lá` $\to$ Criador desistiu (`skipped`) $\to$ Reflexão tardia foi `Sim`.
* **Previsão Neutra (Sem pontuação):**
  - Votos do tipo `Esperar` não somam nem subtraem pontos.
  - Compras devolvidas, reembolsadas ou produtos indisponíveis não penalizam votantes.

---

## 6. Checklist de Execução para Agentes de IA

Ao receber uma tarefa de implementação:

1. **Entender o Requisito:** Consultar [functional-and-non-functional-requirements.md](file:///home/rodrigo/before_i_buy/docs/01-product/functional-and-non-functional-requirements.md).
2. **Consultar a Skill Especialista:**
   - Schema ou SQL? $\to$ Ativar `dba-postgres-architect`.
   - RLS, Auth ou Criptografia? $\to$ Ativar `security-guardian`.
   - Consentimento, LGPD ou OpenGraph? $\to$ Ativar `privacy-lgpd`.
   - Componente Visual ou Telas? $\to$ Ativar `uiux-playful-calm`.
   - Teste automatizado ou E2E? $\to$ Ativar `qa-test-engineer`.
   - Deploy, CI/CD ou Cron? $\to$ Ativar `devops-deploy`.
3. **Escrever os Testes:** Criar testes unitários/integração para os novos comportamentos.
4. **Implementar o Código:** Modificações cirúrgicas, seguindo a tipagem e vertical slices.
5. **Verificar Cobertura & Linter:**
   - Rodar testes e checar se cobertura total permanece $\ge 80\%$.
   - Executar análise estática (`dart analyze` / `npm run lint`).
6. **Finalizar:** Explicar o que foi implementado e o resultado da verificação.
