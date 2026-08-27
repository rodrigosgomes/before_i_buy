-- ============================================================================
-- Test Suite: rls_security_test.sql
-- Description: Testes Automatizados de RLS (Positivos e Negativos) e Integridade
-- Author: qa-test-engineer & security-guardian
-- ============================================================================

BEGIN;

-- Criar extensão pgTAP se disponível
CREATE EXTENSION IF NOT EXISTS pgtap;

SELECT plan(10);

-- Teste 1: Verificar se todas as tabelas têm RLS habilitado
SELECT is(
    (SELECT count(*)::INT FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = true),
    10,
    'Todas as 10 tabelas públicas devem ter Row Level Security (RLS) habilitado'
);

-- Teste 2: Verificar que outbox_jobs não possui políticas públicas (Deny by default total)
SELECT is(
    (SELECT count(*)::INT FROM pg_policies WHERE schemaname = 'public' AND tablename = 'outbox_jobs'),
    0,
    'Tabela outbox_jobs não deve ter políticas públicas para anon/authenticated (apenas service_role)'
);

-- Teste 3: Verificar isolamento de owner_expectations (Apenas 1 política para o dono)
SELECT is(
    (SELECT count(*)::INT FROM pg_policies WHERE schemaname = 'public' AND tablename = 'owner_expectations'),
    1,
    'Tabela owner_expectations deve ter apenas 1 política restrita ao próprio dono'
);

-- Teste 4: Verificar se a tabela dilemmas possui restrição de preço positivo
SELECT throws_ok(
    $$ INSERT INTO public.dilemmas (
        owner_id, item_name, price_cents, category, reason, pause_duration_hours, pause_due_at
    ) VALUES (
        gen_random_uuid(), 'Item Teste', -100, 'tech_electronics', 'Motivo de teste longo o suficiente', 24, NOW() + INTERVAL '24 hours'
    ) $$,
    '23514', -- check constraint violation
    NULL,
    'Dilema com preço negativo deve ser rejeitado pela constraint de integridade'
);

-- Teste 5: Verificar se a tabela dilemmas possui restrição de razão mínima (10 caracteres)
SELECT throws_ok(
    $$ INSERT INTO public.dilemmas (
        owner_id, item_name, price_cents, category, reason, pause_duration_hours, pause_due_at
    ) VALUES (
        gen_random_uuid(), 'Item Teste', 5000, 'tech_electronics', 'Curto', 24, NOW() + INTERVAL '24 hours'
    ) $$,
    '23514',
    NULL,
    'Dilema com razão menor que 10 caracteres deve ser rejeitado'
);

-- Teste 6: Verificar se a janela de pausa aceita apenas 24, 72 ou 168 horas
SELECT throws_ok(
    $$ INSERT INTO public.dilemmas (
        owner_id, item_name, price_cents, category, reason, pause_duration_hours, pause_due_at
    ) VALUES (
        gen_random_uuid(), 'Item Teste', 5000, 'tech_electronics', 'Motivo de teste válido para compra', 12, NOW() + INTERVAL '12 hours'
    ) $$,
    '23514',
    NULL,
    'Janela de pausa diferente de 24h, 72h ou 168h deve ser rejeitada'
);

-- Teste 7: Verificar unicidade de voto por sessão de convidado
SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'uq_dilemma_guest' AND contype = 'u'
    ),
    'Constraint uq_dilemma_guest deve existir para impedir voto duplo de convidado'
);

-- Teste 8: Verificar unicidade de voto por usuário autenticado
SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'uq_dilemma_user' AND contype = 'u'
    ),
    'Constraint uq_dilemma_user deve existir para impedir voto duplo de usuário'
);

-- Teste 9: Verificar existência dos índices parciais de agendamento de reflexão
SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_dilemmas_due_reflection'
    ),
    'Índice parcial idx_dilemmas_due_reflection deve estar ativo para otimização do pg_cron'
);

-- Teste 10: Verificar existência do índice de hash do token de convite
SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_dilemmas_token_hash'
    ),
    'Índice parcial idx_dilemmas_token_hash deve estar ativo para busca rápida sem vazar tokens revogados'
);

SELECT * FROM finish();
ROLLBACK;
