-- ============================================================================
-- Migration: 20260827000001_initial_schema.sql
-- Description: Schema inicial do Before I Buy com Enums, Tabelas e Índices
-- Author: dba-postgres-architect & security-guardian
-- ============================================================================

-- 1. EXTENSÕES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. ENUMS
DO $$ BEGIN
    CREATE TYPE dilemma_state AS ENUM (
        'draft',
        'collecting_votes',
        'decision_due',
        'decided',
        'reflection_due',
        'reflected',
        'closed_private',
        'expired',
        'deleted',
        'moderation_hidden'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE purchase_purpose AS ENUM (
        'for_self',
        'gift'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE decision_type AS ENUM (
        'bought_original',
        'bought_alternative',
        'skipped',
        'unavailable',
        'still_deciding'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE vote_prediction AS ENUM (
        'buy',
        'wait',
        'skip'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE satisfaction_outcome AS ENUM (
        'yes',
        'unsure',
        'no'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE item_category AS ENUM (
        'tech_electronics',
        'fashion_apparel',
        'beauty_personal_care',
        'home_living',
        'hobbies_crafts',
        'gaming_entertainment',
        'food_experiences',
        'tools_hardware',
        'other'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE follow_up_horizon AS ENUM (
        '7_days',
        '30_days',
        '90_days'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE job_status AS ENUM (
        'pending',
        'processing',
        'completed',
        'failed'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. FUNÇÃO UTILITÁRIA PARA TRIGGER UPDATED_AT
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. TABELAS

-- 4.1. Perfis de Usuário (vinculados ao auth.users do Supabase)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name VARCHAR(50) NOT NULL,
    avatar_url TEXT,
    is_adult_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    terms_accepted_version VARCHAR(20) NOT NULL,
    privacy_accepted_version VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trigger_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 4.2. Dilemas (Tentações de Compra)
CREATE TABLE IF NOT EXISTS public.dilemmas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    item_name VARCHAR(80) NOT NULL,
    price_cents BIGINT NOT NULL CHECK (price_cents > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'BRL',
    category item_category NOT NULL,
    purpose purchase_purpose NOT NULL DEFAULT 'for_self',
    reason TEXT NOT NULL CHECK (char_length(reason) >= 10 AND char_length(reason) <= 500),
    image_url TEXT,
    product_url TEXT,
    wanted_since_bucket VARCHAR(30),
    pause_duration_hours INT NOT NULL CHECK (pause_duration_hours IN (24, 72, 168)), -- 24h, 3d, 7d
    pause_due_at TIMESTAMPTZ NOT NULL,
    planned_follow_up_horizon follow_up_horizon NOT NULL DEFAULT '30_days',
    reflection_due_at TIMESTAMPTZ,
    state dilemma_state NOT NULL DEFAULT 'collecting_votes',
    invite_token_hash VARCHAR(64) UNIQUE, -- SHA-256 do token gerado
    is_invite_revoked BOOLEAN NOT NULL DEFAULT FALSE,
    client_idempotency_key UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trigger_dilemmas_updated_at
BEFORE UPDATE ON public.dilemmas
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 4.3. Auto-Previsão Privada do Criador (Owner Self-Prediction / Illusion Filter)
CREATE TABLE IF NOT EXISTS public.owner_expectations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dilemma_id UUID NOT NULL UNIQUE REFERENCES public.dilemmas(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    expected_satisfaction satisfaction_outcome NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4.4. Participações (Sessão de Voto por Usuário Autenticado ou Convidado)
CREATE TABLE IF NOT EXISTS public.participations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dilemma_id UUID NOT NULL REFERENCES public.dilemmas(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    guest_session_id UUID, -- UUID efêmero gerado para o convidado
    display_name VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_user_or_guest CHECK (user_id IS NOT NULL OR guest_session_id IS NOT NULL),
    CONSTRAINT uq_dilemma_user UNIQUE (dilemma_id, user_id),
    CONSTRAINT uq_dilemma_guest UNIQUE (dilemma_id, guest_session_id)
);

-- 4.5. Votos dos Amigos
CREATE TABLE IF NOT EXISTS public.votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    participation_id UUID NOT NULL UNIQUE REFERENCES public.participations(id) ON DELETE CASCADE,
    prediction vote_prediction NOT NULL,
    reason VARCHAR(280),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trigger_votes_updated_at
BEFORE UPDATE ON public.votes
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 4.6. Decisão Real do Criador
CREATE TABLE IF NOT EXISTS public.decisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dilemma_id UUID NOT NULL UNIQUE REFERENCES public.dilemmas(id) ON DELETE CASCADE,
    decision_type decision_type NOT NULL,
    alternative_item_name VARCHAR(80),
    notes TEXT,
    decided_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4.7. Reflexão Tardia do Criador
CREATE TABLE IF NOT EXISTS public.reflections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dilemma_id UUID NOT NULL UNIQUE REFERENCES public.dilemmas(id) ON DELETE CASCADE,
    satisfaction satisfaction_outcome NOT NULL,
    notes TEXT,
    is_returned_or_refunded BOOLEAN NOT NULL DEFAULT FALSE,
    reflected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4.8. Assinatura de Convidado para o Reveal (Opt-in Isolado)
CREATE TABLE IF NOT EXISTS public.guest_reveal_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dilemma_id UUID NOT NULL REFERENCES public.dilemmas(id) ON DELETE CASCADE,
    guest_session_id UUID NOT NULL,
    email VARCHAR(255),
    push_token TEXT,
    is_sent BOOLEAN NOT NULL DEFAULT FALSE,
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '45 days'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_email_or_push CHECK (email IS NOT NULL OR push_token IS NOT NULL),
    CONSTRAINT uq_guest_subscription UNIQUE (dilemma_id, guest_session_id)
);

-- 4.9. Fila Outbox de Notificações e Jobs Agendados
CREATE TABLE IF NOT EXISTS public.outbox_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_type VARCHAR(50) NOT NULL, -- 'reflection_reminder', 'reveal_broadcast', 'data_purge'
    payload JSONB NOT NULL,
    status job_status NOT NULL DEFAULT 'pending',
    scheduled_for TIMESTAMPTZ NOT NULL,
    attempts INT NOT NULL DEFAULT 0,
    max_attempts INT NOT NULL DEFAULT 3,
    last_error TEXT,
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4.10. Denúncias e Moderação
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dilemma_id UUID REFERENCES public.dilemmas(id) ON DELETE SET NULL,
    reporter_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    reason VARCHAR(100) NOT NULL,
    details TEXT,
    is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. ÍNDICES DE PERFORMANCE E INTEGRIDADE

-- Dilemas
CREATE INDEX IF NOT EXISTS idx_dilemmas_owner ON public.dilemmas(owner_id);
CREATE INDEX IF NOT EXISTS idx_dilemmas_token_hash ON public.dilemmas(invite_token_hash) WHERE is_invite_revoked IS FALSE;
CREATE INDEX IF NOT EXISTS idx_dilemmas_due_reflection ON public.dilemmas(reflection_due_at) WHERE state = 'decided';
CREATE INDEX IF NOT EXISTS idx_dilemmas_pause_due ON public.dilemmas(pause_due_at) WHERE state = 'collecting_votes';

-- Participações e Votos
CREATE INDEX IF NOT EXISTS idx_participations_dilemma ON public.participations(dilemma_id);
CREATE INDEX IF NOT EXISTS idx_votes_participation ON public.votes(participation_id);

-- Outbox Jobs
CREATE INDEX IF NOT EXISTS idx_outbox_pending ON public.outbox_jobs(scheduled_for) WHERE status = 'pending';

-- Assinaturas de Reveal
CREATE INDEX IF NOT EXISTS idx_guest_subscriptions_pending ON public.guest_reveal_subscriptions(dilemma_id) WHERE is_sent IS FALSE;
