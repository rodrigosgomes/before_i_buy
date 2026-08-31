-- Negative authorization contract. A guest must reach a dilemma only through a
-- narrowly scoped token-exchange function, never through direct table access.
BEGIN;

CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path TO extensions, public, auth;

SELECT plan(7);

SELECT is_empty(
    $$
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'dilemmas'
      AND cmd IN ('SELECT', 'ALL')
      AND roles && ARRAY['public', 'anon']::name[]
    $$,
    'Anonymous clients have no direct SELECT policy on dilemmas'
);

SELECT is_empty(
    $$
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'participations'
      AND cmd IN ('SELECT', 'ALL')
      AND roles && ARRAY['public', 'anon']::name[]
    $$,
    'Anonymous clients have no direct SELECT policy on participations'
);

SELECT is_empty(
    $$
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'votes'
      AND cmd IN ('SELECT', 'ALL')
      AND roles && ARRAY['public', 'anon']::name[]
    $$,
    'Anonymous clients have no direct SELECT policy on votes'
);

SELECT is_empty(
    $$
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'owner_expectations'
      AND roles && ARRAY['public', 'anon']::name[]
    $$,
    'Anonymous clients cannot read or write owner expectations'
);

SELECT ok(
    EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'dilemmas'
          AND policyname = 'dilemmas_owner_all'
          AND roles = ARRAY['authenticated']::name[]
          AND qual LIKE '%owner_id = auth.uid()%'
          AND with_check LIKE '%owner_id = auth.uid()%'
    ),
    'Only an authenticated owner receives direct dilemma mutation access'
);

SELECT is_empty(
    $$
    SELECT *
    FROM public.exchange_invite_token('not-a-valid-invite-token')
    $$,
    'An invalid invite token reveals no dilemma'
);

SELECT is(
    (
        SELECT count(*)::INT
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'outbox_jobs'
          AND roles && ARRAY['public', 'anon', 'authenticated']::name[]
    ),
    0,
    'No client role can access the notification outbox'
);

SELECT * FROM finish();
ROLLBACK;
