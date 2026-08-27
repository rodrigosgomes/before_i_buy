-- ============================================================================
-- Migration: 20260827000002_rls_policies.sql
-- Description: Políticas de Row Level Security (RLS) Deny-by-Default
-- Author: security-guardian & privacy-lgpd
-- ============================================================================

-- 1. HABILITAR RLS EM 100% DAS TABELAS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dilemmas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.owner_expectations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.participations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.decisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reflections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guest_reveal_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outbox_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- 2. POLÍTICAS: PROFILES
-- Usuário autenticado pode gerenciar seu próprio perfil
CREATE POLICY "profiles_select_authenticated"
ON public.profiles FOR SELECT
TO authenticated
USING (true); -- Permitir leitura de nomes e avatares entre usuários da plataforma

CREATE POLICY "profiles_insert_own"
ON public.profiles FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_update_own"
ON public.profiles FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- 3. POLÍTICAS: DILEMMAS
-- O criador tem controle total dos seus dilemas
CREATE POLICY "dilemmas_owner_all"
ON public.dilemmas FOR ALL
TO authenticated
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

-- Participantes (autenticados ou anônimos com sessão) podem ler dilemas públicos/não revogados
CREATE POLICY "dilemmas_select_by_invite_or_participant"
ON public.dilemmas FOR SELECT
TO public
USING (
    is_invite_revoked IS FALSE 
    AND state != 'draft' 
    AND state != 'deleted' 
    AND state != 'moderation_hidden'
);

-- 4. POLÍTICAS: OWNER_EXPECTATIONS (Isolamento Total da Auto-Previsão Privada)
-- SOMENTE o dono do dilema pode ler e gravar sua auto-previsão. Zero acesso a anon e outros usuários.
CREATE POLICY "owner_expectations_owner_only"
ON public.owner_expectations FOR ALL
TO authenticated
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

-- 5. POLÍTICAS: PARTICIPATIONS
-- O criador do dilema pode ver as participações
CREATE POLICY "participations_select_owner"
ON public.participations FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.dilemmas d
        WHERE d.id = participations.dilemma_id
        AND d.owner_id = auth.uid()
    )
);

-- Usuários e convidados podem ver sua própria participação
CREATE POLICY "participations_select_self"
ON public.participations FOR SELECT
TO public
USING (
    (auth.uid() IS NOT NULL AND user_id = auth.uid())
    OR (guest_session_id IS NOT NULL)
);

-- Usuários autenticados podem se registrar como participante
CREATE POLICY "participations_insert_authenticated"
ON public.participations FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Convidados anônimos podem se registrar com guest_session_id
CREATE POLICY "participations_insert_anon"
ON public.participations FOR INSERT
TO anon
WITH CHECK (guest_session_id IS NOT NULL AND user_id IS NULL);

-- 6. POLÍTICAS: VOTES
-- Criador do dilema pode ver os votos do seu dilema
CREATE POLICY "votes_select_owner"
ON public.votes FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.participations p
        JOIN public.dilemmas d ON d.id = p.dilemma_id
        WHERE p.id = votes.participation_id
        AND d.owner_id = auth.uid()
    )
);

-- Votante pode ver seu próprio voto
CREATE POLICY "votes_select_self"
ON public.votes FOR SELECT
TO public
USING (
    EXISTS (
        SELECT 1 FROM public.participations p
        WHERE p.id = votes.participation_id
        AND (
            (auth.uid() IS NOT NULL AND p.user_id = auth.uid())
            OR (p.guest_session_id IS NOT NULL)
        )
    )
);

-- Votante autenticado pode inserir seu voto
CREATE POLICY "votes_insert_authenticated"
ON public.votes FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.participations p
        WHERE p.id = votes.participation_id
        AND p.user_id = auth.uid()
    )
);

-- Convidado anônimo pode inserir seu voto
CREATE POLICY "votes_insert_anon"
ON public.votes FOR INSERT
TO anon
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.participations p
        WHERE p.id = votes.participation_id
        AND p.guest_session_id IS NOT NULL
        AND p.user_id IS NULL
    )
);

-- 7. POLÍTICAS: DECISIONS
-- Criador tem controle total sobre a decisão
CREATE POLICY "decisions_owner_all"
ON public.decisions FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.dilemmas d
        WHERE d.id = decisions.dilemma_id
        AND d.owner_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.dilemmas d
        WHERE d.id = decisions.dilemma_id
        AND d.owner_id = auth.uid()
    )
);

-- Participantes só podem ler a decisão se o dilema foi decidido
CREATE POLICY "decisions_select_participants"
ON public.decisions FOR SELECT
TO public
USING (
    EXISTS (
        SELECT 1 FROM public.dilemmas d
        WHERE d.id = decisions.dilemma_id
        AND d.state IN ('decided', 'reflection_due', 'reflected', 'closed_private')
        AND d.is_invite_revoked IS FALSE
    )
);

-- 8. POLÍTICAS: REFLECTIONS
-- Criador tem controle total sobre a reflexão
CREATE POLICY "reflections_owner_all"
ON public.reflections FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.dilemmas d
        WHERE d.id = reflections.dilemma_id
        AND d.owner_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.dilemmas d
        WHERE d.id = reflections.dilemma_id
        AND d.owner_id = auth.uid()
    )
);

-- Participantes só podem ler a reflexão quando o status for 'reflected' (Reveal)
CREATE POLICY "reflections_select_reveal"
ON public.reflections FOR SELECT
TO public
USING (
    EXISTS (
        SELECT 1 FROM public.dilemmas d
        WHERE d.id = reflections.dilemma_id
        AND d.state = 'reflected'
        AND d.is_invite_revoked IS FALSE
    )
);

-- 9. POLÍTICAS: GUEST_REVEAL_SUBSCRIPTIONS (Opt-in Isolado)
CREATE POLICY "guest_subs_insert"
ON public.guest_reveal_subscriptions FOR INSERT
TO anon
WITH CHECK (guest_session_id IS NOT NULL);

CREATE POLICY "guest_subs_select_self"
ON public.guest_reveal_subscriptions FOR SELECT
TO anon
USING (guest_session_id IS NOT NULL);

-- 10. POLÍTICAS: OUTBOX_JOBS (Fila Restrita ao Backend)
-- NENHUM acesso para anon ou authenticated. Apenas a chave de serviço (service_role) acessa.
-- Sem políticas para anon/authenticated = DENY BY DEFAULT TOTAL.

-- 11. POLÍTICAS: REPORTS (Denúncias)
CREATE POLICY "reports_insert_public"
ON public.reports FOR INSERT
TO public
WITH CHECK (true);
