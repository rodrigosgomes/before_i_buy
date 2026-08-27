-- ============================================================================
-- Migration: 20260827000003_secure_functions.sql
-- Description: Funções Stored Procedures seguras (RPCs) para o ciclo do produto
-- Author: dba-postgres-architect & security-guardian
-- ============================================================================

-- 1. FUNÇÃO PARA PUBLICAR DILEMA E GERAR HASH DO TOKEN COM SHA-256
CREATE OR REPLACE FUNCTION public.publish_dilemma(
    p_item_name VARCHAR(80),
    p_price_cents BIGINT,
    p_currency VARCHAR(3),
    p_category item_category,
    p_purpose purchase_purpose,
    p_reason TEXT,
    p_image_url TEXT,
    p_product_url TEXT,
    p_wanted_since VARCHAR(30),
    p_pause_hours INT,
    p_token_plain TEXT,
    p_client_idempotency_key UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    v_owner_id UUID;
    v_token_hash VARCHAR(64);
    v_dilemma_id UUID;
    v_pause_due_at TIMESTAMPTZ;
    v_follow_up follow_up_horizon;
BEGIN
    -- Validar autenticação
    v_owner_id := auth.uid();
    IF v_owner_id IS NULL THEN
        RAISE EXCEPTION 'Apenas usuários autenticados podem publicar dilemas.';
    END IF;

    -- Validar horas de pausa permitidas (24, 72 ou 168)
    IF p_pause_hours NOT IN (24, 72, 168) THEN
        RAISE EXCEPTION 'Janela de pausa inválida. Use 24, 72 ou 168 horas.';
    END IF;

    -- Calcular data limite da pausa
    v_pause_due_at := NOW() + (p_pause_hours || ' hours')::INTERVAL;

    -- Definir horizonte de follow-up por categoria
    IF p_category IN ('food_experiences') THEN
        v_follow_up := '7_days';
    ELSE
        v_follow_up := '30_days';
    END IF;

    -- Calcular hash SHA-256 do token
    v_token_hash := encode(digest(p_token_plain, 'sha256'), 'hex');

    -- Inserir dilema
    INSERT INTO public.dilemmas (
        owner_id,
        item_name,
        price_cents,
        currency,
        category,
        purpose,
        reason,
        image_url,
        product_url,
        wanted_since_bucket,
        pause_duration_hours,
        pause_due_at,
        planned_follow_up_horizon,
        state,
        invite_token_hash,
        client_idempotency_key
    ) VALUES (
        v_owner_id,
        p_item_name,
        p_price_cents,
        COALESCE(p_currency, 'BRL'),
        p_category,
        p_purpose,
        p_reason,
        p_image_url,
        p_product_url,
        p_wanted_since,
        p_pause_hours,
        v_pause_due_at,
        v_follow_up,
        'collecting_votes',
        v_token_hash,
        p_client_idempotency_key
    )
    RETURNING id INTO v_dilemma_id;

    RETURN v_dilemma_id;
END;
$$;

-- 2. FUNÇÃO PARA VALIDAR TOKEN E RETORNAR DADOS PÚBLICOS DO DILEMA
CREATE OR REPLACE FUNCTION public.exchange_invite_token(
    p_token_plain TEXT
)
RETURNS TABLE (
    id UUID,
    item_name VARCHAR(80),
    price_cents BIGINT,
    currency VARCHAR(3),
    category item_category,
    purpose purchase_purpose,
    reason TEXT,
    image_url TEXT,
    product_url TEXT,
    pause_due_at TIMESTAMPTZ,
    state dilemma_state,
    owner_name VARCHAR(50),
    owner_avatar TEXT,
    total_votes BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    v_token_hash VARCHAR(64);
BEGIN
    -- Calcular hash
    v_token_hash := encode(digest(p_token_plain, 'sha256'), 'hex');

    RETURN QUERY
    SELECT 
        d.id,
        d.item_name,
        d.price_cents,
        d.currency,
        d.category,
        d.purpose,
        d.reason,
        d.image_url,
        d.product_url,
        d.pause_due_at,
        d.state,
        p.display_name AS owner_name,
        p.avatar_url AS owner_avatar,
        (SELECT COUNT(*) FROM public.participations pt WHERE pt.dilemma_id = d.id) AS total_votes
    FROM public.dilemmas d
    JOIN public.profiles p ON p.id = d.owner_id
    WHERE d.invite_token_hash = v_token_hash
      AND d.is_invite_revoked IS FALSE
      AND d.state NOT IN ('draft', 'deleted', 'moderation_hidden');
END;
$$;

-- 3. FUNÇÃO ATÔMICA PARA REGISTRAR DECISÃO DO CRIADOR E AGENDAR REFLEXÃO
CREATE OR REPLACE FUNCTION public.record_decision(
    p_dilemma_id UUID,
    p_decision_type decision_type,
    p_alternative_item_name VARCHAR(80) DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    v_owner_id UUID;
    v_category item_category;
    v_reflection_due TIMESTAMPTZ;
    v_horizon_days INT;
BEGIN
    v_owner_id := auth.uid();
    IF v_owner_id IS NULL THEN
        RAISE EXCEPTION 'Apenas o criador autenticado pode registrar a decisão.';
    END IF;

    -- Obter e validar dilema
    SELECT category INTO v_category
    FROM public.dilemmas
    WHERE id = p_dilemma_id AND owner_id = v_owner_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Dilema não encontrado ou você não tem permissão.';
    END IF;

    -- Calcular data da reflexão tardia:
    -- Se desistiu (skipped): 7 dias
    -- Se comprou perecível (food_experiences): 7 dias
    -- Se comprou durável: 30 dias
    IF p_decision_type = 'skipped' OR v_category = 'food_experiences' THEN
        v_horizon_days := 7;
    ELSE
        v_horizon_days := 30;
    END IF;

    v_reflection_due := NOW() + (v_horizon_days || ' days')::INTERVAL;

    -- Inserir registro de decisão
    INSERT INTO public.decisions (
        dilemma_id,
        decision_type,
        alternative_item_name,
        notes
    ) VALUES (
        p_dilemma_id,
        p_decision_type,
        p_alternative_item_name,
        p_notes
    );

    -- Atualizar estado do dilema
    UPDATE public.dilemmas
    SET state = 'decided',
        reflection_due_at = v_reflection_due,
        updated_at = NOW()
    WHERE id = p_dilemma_id;

    -- Enfileirar no Outbox para disparo futuro da notificação de reflexão
    INSERT INTO public.outbox_jobs (
        job_type,
        payload,
        scheduled_for
    ) VALUES (
        'reflection_reminder',
        jsonb_build_object(
            'dilemma_id', p_dilemma_id,
            'owner_id', v_owner_id,
            'decision_type', p_decision_type
        ),
        v_reflection_due
    );
END;
$$;

-- 4. FUNÇÃO ATÔMICA PARA REGISTRAR REFLEXÃO E ENFILEIRAR BROADCAST DO REVEAL
CREATE OR REPLACE FUNCTION public.record_reflection(
    p_dilemma_id UUID,
    p_satisfaction satisfaction_outcome,
    p_notes TEXT DEFAULT NULL,
    p_is_returned BOOLEAN DEFAULT FALSE
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    v_owner_id UUID;
BEGIN
    v_owner_id := auth.uid();
    IF v_owner_id IS NULL THEN
        RAISE EXCEPTION 'Apenas o criador autenticado pode registrar a reflexão.';
    END IF;

    -- Validar posse do dilema
    IF NOT EXISTS (SELECT 1 FROM public.dilemmas WHERE id = p_dilemma_id AND owner_id = v_owner_id) THEN
        RAISE EXCEPTION 'Dilema não encontrado ou você não tem permissão.';
    END IF;

    -- Inserir reflexão
    INSERT INTO public.reflections (
        dilemma_id,
        satisfaction,
        notes,
        is_returned_or_refunded
    ) VALUES (
        p_dilemma_id,
        p_satisfaction,
        p_notes,
        p_is_returned
    );

    -- Atualizar estado do dilema para 'reflected'
    UPDATE public.dilemmas
    SET state = 'reflected',
        updated_at = NOW()
    WHERE id = p_dilemma_id;

    -- Enfileirar job de disparo do Reveal para os votantes
    INSERT INTO public.outbox_jobs (
        job_type,
        payload,
        scheduled_for
    ) VALUES (
        'reveal_broadcast',
        jsonb_build_object(
            'dilemma_id', p_dilemma_id,
            'satisfaction', p_satisfaction
        ),
        NOW() -- Envio imediato
    );
END;
$$;
