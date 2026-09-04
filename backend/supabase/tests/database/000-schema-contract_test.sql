-- Structural contract for the exposed database. Behavioural authorization tests
-- live in 010-rls-negative-access_test.sql.
BEGIN;

CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path TO extensions, public, auth;

SELECT plan(11);

SELECT is(
    (
        SELECT count(*)::INT
        FROM pg_tables
        WHERE schemaname = 'public'
          AND tablename IN (
              'profiles', 'dilemmas', 'owner_expectations', 'participations',
              'votes', 'decisions', 'reflections', 'guest_reveal_subscriptions',
              'outbox_jobs', 'reports', 'creator_consent_versions'
          )
          AND rowsecurity
    ),
    11,
    'Every exposed product table has Row Level Security enabled'
);

SELECT is(
    (
        SELECT count(*)::INT
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'outbox_jobs'
    ),
    0,
    'outbox_jobs has no policy for client roles'
);

SELECT is(
    (
        SELECT count(*)::INT
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'owner_expectations'
    ),
    1,
    'owner_expectations has exactly one owner-only policy'
);

SELECT throws_ok(
    $$ INSERT INTO public.dilemmas (
        owner_id, item_name, price_cents, category, reason, pause_duration_hours, pause_due_at
    ) VALUES (
        gen_random_uuid(), 'Item Teste', -100, 'tech_electronics', 'Motivo de teste longo o suficiente', 24, NOW() + INTERVAL '24 hours'
    ) $$,
    '23514',
    NULL,
    'A negative price is rejected by a database constraint'
);

SELECT throws_ok(
    $$ INSERT INTO public.dilemmas (
        owner_id, item_name, price_cents, category, reason, pause_duration_hours, pause_due_at
    ) VALUES (
        gen_random_uuid(), 'Item Teste', 5000, 'tech_electronics', 'Curto', 24, NOW() + INTERVAL '24 hours'
    ) $$,
    '23514',
    NULL,
    'A reason shorter than ten characters is rejected'
);

SELECT throws_ok(
    $$ INSERT INTO public.dilemmas (
        owner_id, item_name, price_cents, category, reason, pause_duration_hours, pause_due_at
    ) VALUES (
        gen_random_uuid(), 'Item Teste', 5000, 'tech_electronics', 'Motivo de teste valido para compra', 12, NOW() + INTERVAL '12 hours'
    ) $$,
    '23514',
    NULL,
    'Only 24, 72, and 168 hour pause windows are accepted'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_dilemma_guest' AND contype = 'u'
    ),
    'A guest has at most one active participation per dilemma'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_dilemma_user' AND contype = 'u'
    ),
    'An authenticated participant has at most one participation per dilemma'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public' AND indexname = 'idx_dilemmas_due_reflection'
    ),
    'The reflection scheduling index exists'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public' AND indexname = 'idx_dilemmas_token_hash'
    ),
    'The invite-token hash index exists'
);

SELECT ok(
    EXISTS (
        SELECT 1
        FROM public.creator_consent_versions
        WHERE document_kind = 'terms'
          AND version = 'internal-demo-v1'
          AND is_active
          AND is_internal_demo
    ),
    'The development-only consent version is explicit and active'
);

SELECT * FROM finish();
ROLLBACK;
