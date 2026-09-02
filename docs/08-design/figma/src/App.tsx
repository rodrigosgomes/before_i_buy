import { useState } from 'react'
import {
  BibBrandMark,
  BibPageShell,
  BibTopBar,
  BibDraftBanner,
  BibPrimaryButton,
  BibSecondaryButton,
  BibTextButton,
  BibBottomActionBar,
  BibTextField,
  BibCurrencyField,
  BibSelectField,
  BibSegmentedChoice,
  BibPrivacyNotice,
  BibDilemmaSummary,
  BibGuestPreviewFrame,
  BibStatusChip,
  BibEmptyState,
  BibVoteOption,
  BibVoteDistribution,
  BibLoadingBlock,
  BibInlineMessage,
  IconShare,
  IconAlert,
  IconForward,
  IconCheck,
} from './components/Bib'

// ─── Fixture ─────────────────────────────────────────────────────────────────

const FIXTURE = {
  itemName: 'Fone com cancelamento de ruído',
  price: 'R$ 2.400,00',
  category: 'Tecnologia',
  reason: 'Quero mais foco para trabalhar e viajar com menos ruído.',
  purpose: 'Para mim',
  pause: '3 dias',
  remaining: '2 dias',
  creatorName: 'Lu',
  votes: { buy: 1, wait: 2, skip: 1 },
}

// ─── Screen definitions ───────────────────────────────────────────────────────

const SCREENS = [
  { id: 'E1-S01', label: 'Home vazia', flow: 'Criador' },
  { id: 'E1-S02', label: 'Nova tentação', flow: 'Criador' },
  { id: 'E1-S03', label: 'Revisão', flow: 'Criador' },
  { id: 'E1-S04', label: 'Prévia', flow: 'Criador' },
  { id: 'E1-S05', label: 'Publicado', flow: 'Criador' },
  { id: 'E1-S06', label: 'Sem votos', flow: 'Criador' },
  { id: 'E1-S07', label: 'Abrindo', flow: 'Convidado' },
  { id: 'E1-S08', label: 'Votação', flow: 'Convidado' },
  { id: 'E1-S09', label: 'Selecionado', flow: 'Convidado' },
  { id: 'E1-S10', label: 'Confirmado', flow: 'Convidado' },
  { id: 'E1-S11', label: 'Agregados', flow: 'Convidado' },
]

// ─── Hero Illustration (S01) ──────────────────────────────────────────────────

function HeroIllustration() {
  return (
    <svg viewBox="0 0 320 220" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" className="w-full max-w-[320px]">
      {/* Background blob */}
      <ellipse cx="160" cy="115" rx="130" ry="100" fill="#EFECE6" />
      {/* Left speech bubble */}
      <rect x="36" y="58" width="108" height="62" rx="20" fill="#DCEAE5" />
      <path d="M52 120L44 140L72 120Z" fill="#DCEAE5" />
      {/* Right speech bubble */}
      <rect x="168" y="78" width="96" height="54" rx="18" fill="#E8E3EC" />
      <path d="M228 132L236 148L212 132Z" fill="#E8E3EC" />
      {/* Pause mark - brand signal in center */}
      <rect x="148" y="86" width="8" height="28" rx="4" fill="#C56C51" />
      <rect x="162" y="86" width="8" height="28" rx="4" fill="#C56C51" fillOpacity="0.38" />
      {/* Left bubble dots */}
      <circle cx="64" cy="89" r="5" fill="#89AFA3" />
      <circle cx="82" cy="89" r="5" fill="#89AFA3" fillOpacity="0.6" />
      <circle cx="100" cy="89" r="5" fill="#89AFA3" fillOpacity="0.3" />
      {/* Right bubble detail */}
      <rect x="183" y="97" width="66" height="6" rx="3" fill="#9C92A6" fillOpacity="0.5" />
      <rect x="183" y="110" width="48" height="6" rx="3" fill="#9C92A6" fillOpacity="0.3" />
      {/* Decorative dots */}
      <circle cx="32" cy="52" r="7" fill="#F2B49F" fillOpacity="0.7" />
      <circle cx="292" cy="158" r="10" fill="#AFC8D8" fillOpacity="0.6" />
      <circle cx="278" cy="68" r="5" fill="#E8D78C" fillOpacity="0.8" />
      <circle cx="50" cy="170" r="8" fill="#CBBCA9" fillOpacity="0.5" />
    </svg>
  )
}

// ─── S01 — Empty Home ─────────────────────────────────────────────────────────

function S01EmptyHome({ onNext }: { onNext: () => void }) {
  return (
    <BibPageShell>
      {/* Brand bar */}
      <div className="flex items-center gap-2.5 px-4 h-14 flex-shrink-0">
        <BibBrandMark size={28} />
        <span className="font-display text-[15px] font-[700] text-text tracking-tight">Before I Buy</span>
      </div>

      <div className="flex-1 flex flex-col px-4 pb-4">
        {/* Hero section */}
        <div className="flex justify-center pt-4 pb-6">
          <HeroIllustration />
        </div>

        {/* Headlines */}
        <div className="mb-6">
          <h1 className="font-display text-[28px] font-[700] text-text leading-[34px] mb-3">
            Um pouco de espaço antes de decidir
          </h1>
          <p className="text-[15px] text-muted leading-relaxed">
            Organize a vontade, peça perspectiva a pessoas próximas e escolha no seu tempo.
          </p>
        </div>

        {/* 3 Chapters */}
        <div className="flex flex-col gap-2.5 mb-6">
          {[
            { num: '01', label: 'Conte o que está pensando', color: '#DCEAE5', dot: '#89AFA3' },
            { num: '02', label: 'Ouça perspectivas', color: '#E8E3EC', dot: '#9C92A6' },
            { num: '03', label: 'Decida você', color: '#E9E0D5', dot: '#CBBCA9' },
          ].map((ch) => (
            <div key={ch.num} className="flex items-center gap-3.5 px-4 py-3 rounded-[16px]" style={{ backgroundColor: ch.color }}>
              <span className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0" style={{ backgroundColor: ch.dot }}>
                <span className="text-[10px] font-[700] text-white">{ch.num}</span>
              </span>
              <span className="text-[14px] font-[600] text-text">{ch.label}</span>
            </div>
          ))}
        </div>

        {/* Privacy notice */}
        <div className="mb-6">
          <BibPrivacyNotice
            variant="neutral"
            title="Seus dilemas são privados"
            body="Somente quem recebe o link consegue abrir. Nada é público ou listado."
          />
        </div>
      </div>

      <BibBottomActionBar>
        <BibPrimaryButton onClick={onNext}>
          Criar minha primeira tentação
        </BibPrimaryButton>
      </BibBottomActionBar>
    </BibPageShell>
  )
}

// ─── S02 — New Temptation ────────────────────────────────────────────────────

function S02NewTemptation({ onNext, onBack }: { onNext: () => void; onBack: () => void }) {
  const [itemName, setItemName] = useState('')
  const [price, setPrice] = useState('')
  const [category, setCategory] = useState('Tecnologia')
  const [reason, setReason] = useState('')
  const [purpose, setPurpose] = useState('Para mim')
  const [pause, setPause] = useState('3 dias')

  const canReview = itemName.length >= 2 && price.length > 0 && reason.length >= 10

  return (
    <BibPageShell>
      <BibTopBar title="Nova tentação" onBack={onBack} />
      <BibDraftBanner />

      <div className="flex-1 overflow-y-auto px-4 pb-4 flex flex-col gap-5">
        <BibTextField
          label="Nome do item"
          value={itemName}
          onChange={setItemName}
          helper="De 2 a 80 caracteres"
          maxLength={80}
          counter
          placeholder="Ex: Tênis de corrida, Curso online…"
        />

        <BibCurrencyField value={price} onChange={setPrice} />

        <BibSelectField
          label="Categoria"
          value={category}
          onChange={setCategory}
          options={['Tecnologia', 'Moda e Estilo', 'Casa e Decoração', 'Saúde e Bem-estar', 'Educação', 'Lazer', 'Outro']}
        />

        {/* Expressive reason section */}
        <div>
          <div className="bg-peach/20 rounded-[20px] px-4 pt-4 pb-3 mb-3">
            <p className="font-display text-[16px] font-[700] text-text mb-1">
              Por que você está pensando nisso agora?
            </p>
            <p className="text-[12px] text-muted leading-relaxed">
              O que você espera que isso mude, substitua ou torne possível?
            </p>
          </div>
          <BibTextField
            label=""
            value={reason}
            onChange={setReason}
            multiline
            rows={4}
            maxLength={500}
            counter
            placeholder="Descreva com suas próprias palavras…"
            helper={reason.length < 10 && reason.length > 0 ? 'Mínimo de 10 caracteres' : undefined}
          />
        </div>

        <BibSegmentedChoice
          label="É para quem?"
          value={purpose}
          onChange={setPurpose}
          options={[
            { value: 'Para mim', label: 'Para mim' },
            { value: 'É um presente', label: 'É um presente' },
          ]}
        />

        <BibSegmentedChoice
          label="Quanto espaço você quer antes de decidir?"
          value={pause}
          onChange={setPause}
          options={[
            { value: '24 horas', label: '24 horas', sub: 'Uma noite de sono' },
            { value: '3 dias', label: '3 dias', sub: 'Recomendado' },
            { value: '7 dias', label: '7 dias', sub: 'Uma semana para pensar' },
          ]}
        />
      </div>

      <BibBottomActionBar>
        {!canReview && itemName.length === 0 && (
          <p className="text-[12px] text-muted text-center">Preencha os campos para continuar</p>
        )}
        <BibPrimaryButton onClick={onNext} disabled={!canReview}>
          Revisar
        </BibPrimaryButton>
      </BibBottomActionBar>
    </BibPageShell>
  )
}

// ─── S03 — Dilemma Review ────────────────────────────────────────────────────

function S03DilemmaReview({ onNext, onBack }: { onNext: () => void; onBack: () => void }) {
  return (
    <BibPageShell>
      <BibTopBar title="Revisar" onBack={onBack} />
      <BibDraftBanner />

      <div className="flex-1 px-4 pb-4 flex flex-col gap-4">
        <div>
          <h2 className="font-display text-[22px] font-[700] text-text leading-tight mb-1.5">
            Tudo certo para pedir uma perspectiva?
          </h2>
          <p className="text-[14px] text-muted leading-relaxed">
            Confira com calma. Nada foi compartilhado ainda.
          </p>
        </div>

        {/* Section: O que você está considerando */}
        <div>
          <p className="text-[11px] font-[700] text-muted uppercase tracking-widest mb-2">
            O que você está considerando
          </p>
          <BibDilemmaSummary {...FIXTURE} />
        </div>

        {/* Section: Pausa escolhida */}
        <div className="bg-surface rounded-[20px] p-4 shadow-[0_2px_12px_rgba(79,93,101,0.06)]">
          <p className="text-[11px] font-[700] text-muted uppercase tracking-widest mb-2">Pausa escolhida</p>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-wait flex items-center justify-center">
              <svg width="18" height="18" viewBox="0 0 18 18" fill="none" aria-hidden="true">
                <circle cx="9" cy="9" r="7" stroke="#9C92A6" strokeWidth="1.5" />
                <path d="M9 5.5V9l2.5 2.5" stroke="#9C92A6" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
            <div>
              <p className="font-[600] text-[15px] text-text">3 dias</p>
              <p className="text-[12px] text-muted">A pausa termina automaticamente</p>
            </div>
          </div>
        </div>

        <BibPrivacyNotice
          variant="neutral"
          title="Nada foi compartilhado"
          body="O convite só é criado quando você publicar explicitamente na próxima etapa."
        />
      </div>

      <BibBottomActionBar>
        <BibPrimaryButton onClick={onNext}>
          Ver como meus amigos vão ver
        </BibPrimaryButton>
        <BibSecondaryButton onClick={onBack}>
          Editar
        </BibSecondaryButton>
      </BibBottomActionBar>
    </BibPageShell>
  )
}

// ─── S04 — Guest Preview ─────────────────────────────────────────────────────

function S04GuestPreview({ onNext, onBack }: { onNext: () => void; onBack: () => void }) {
  return (
    <BibPageShell>
      <BibTopBar title="Prévia" subtitle="Como o convite vai aparecer" onBack={onBack} />

      <div className="flex-1 pb-4 flex flex-col gap-4">
        <div className="px-4">
          <p className="text-[14px] text-muted leading-relaxed">
            Somente quem abrir um link válido verá estas informações.
          </p>
        </div>

        {/* Forwarding warning */}
        <div className="mx-4 flex items-start gap-2.5 p-3.5 rounded-[14px] bg-warning">
          <span className="text-[#8F6A0A] mt-0.5 flex-shrink-0"><IconForward size={15} /></span>
          <div>
            <p className="text-[13px] font-[700] text-[#5C4500]">Links podem ser encaminhados</p>
            <p className="text-[12px] text-[#7A5A00] mt-0.5">Você poderá revogar o acesso quando quiser.</p>
          </div>
        </div>

        {/* The actual preview frame */}
        <BibGuestPreviewFrame>
          <div className="px-4 pt-4 pb-6 flex flex-col gap-4">
            <div className="flex items-center gap-2">
              <BibBrandMark size={22} />
              <span className="font-display text-[13px] font-[700] text-text">Before I Buy</span>
            </div>
            <div>
              <p className="font-display text-[17px] font-[700] text-text leading-snug mb-0.5">
                Lu quer sua perspectiva
              </p>
              <p className="text-[12px] text-muted">
                Você foi convidado a opinar sobre uma decisão de compra.
              </p>
            </div>
            <BibDilemmaSummary {...FIXTURE} remaining={FIXTURE.remaining} />
            <div>
              <p className="text-[13px] font-[700] text-text mb-2.5">
                O que a Lu provavelmente vai ficar feliz de ter feito?
              </p>
              <div className="flex flex-col gap-2">
                <BibVoteOption type="buy" />
                <BibVoteOption type="wait" />
                <BibVoteOption type="skip" />
              </div>
            </div>
            <p className="text-[12px] text-muted text-center">
              Seu palpite ajuda. A decisão final é da Lu.
            </p>
          </div>
        </BibGuestPreviewFrame>
      </div>

      <BibBottomActionBar>
        <BibPrimaryButton onClick={onNext}>
          Continuar para publicar
        </BibPrimaryButton>
        <BibSecondaryButton onClick={onBack}>
          Voltar e editar
        </BibSecondaryButton>
      </BibBottomActionBar>
    </BibPageShell>
  )
}

// ─── S05 — Published & Share ──────────────────────────────────────────────────

function S05PublishedShare({ onNext, onBack }: { onNext: () => void; onBack: () => void }) {
  return (
    <BibPageShell>
      <BibTopBar brandMark onBack={undefined} />

      <div className="flex-1 px-4 pb-4 flex flex-col gap-5">
        {/* Micro celebration */}
        <div className="flex flex-col items-center text-center pt-4 pb-2">
          <div className="w-16 h-16 rounded-full bg-buy flex items-center justify-center mb-4 shadow-[0_4px_20px_rgba(137,175,163,0.35)]">
            <span className="text-[#2D7A6A]"><IconCheck size={28} /></span>
          </div>
          <h1 className="font-display text-[26px] font-[700] text-text leading-tight mb-2">
            Seu dilema está pronto
          </h1>
          <p className="text-[14px] text-muted leading-relaxed max-w-[260px]">
            Ele continua privado até você compartilhar o convite.
          </p>
        </div>

        <div className="flex justify-center">
          <BibStatusChip label="Convite ativo · privado e não listado" type="active" />
        </div>

        <BibDilemmaSummary {...FIXTURE} compact />

        <BibPrivacyNotice
          variant="neutral"
          title="Prévia genérica no WhatsApp e outros apps"
          body="Item, preço e seu nome só aparecem depois que o link é validado. A prévia nunca inclui dados do dilema."
        />
      </div>

      <BibBottomActionBar>
        <BibPrimaryButton onClick={onNext} icon={<IconShare size={18} />}>
          Compartilhar convite
        </BibPrimaryButton>
        <BibTextButton onClick={onBack}>Agora não</BibTextButton>
      </BibBottomActionBar>
    </BibPageShell>
  )
}

// ─── S06 — Active Dilemma Without Votes ──────────────────────────────────────

function S06ActiveDilemma({ onNext, onBack }: { onNext: () => void; onBack: () => void }) {
  return (
    <BibPageShell>
      <BibTopBar title="Meu dilema" onBack={onBack} />

      <div className="flex-1 px-4 pb-4 flex flex-col gap-4">
        {/* Status + time */}
        <div className="flex items-center justify-between">
          <BibStatusChip label="Coletando palpites" type="active" />
          <span className="text-[13px] text-muted font-[500]">A pausa termina em 2 dias</span>
        </div>

        <BibDilemmaSummary {...FIXTURE} compact />

        {/* Empty state for votes */}
        <div className="bg-surface rounded-[24px] shadow-[0_2px_12px_rgba(79,93,101,0.06)]">
          <BibEmptyState
            title="Ainda sem palpites"
            body="Tudo bem. Compartilhe com alguém cuja perspectiva importa para você."
          />
        </div>

        <BibPrivacyNotice
          variant="neutral"
          title="A decisão final continua sendo sua"
          body="Os palpites dos amigos são perspectivas, não votos vinculantes."
        />
      </div>

      <BibBottomActionBar>
        <BibPrimaryButton onClick={onNext} icon={<IconShare size={18} />}>
          Compartilhar novamente
        </BibPrimaryButton>
        <BibSecondaryButton onClick={onBack}>
          Gerenciar convite
        </BibSecondaryButton>
      </BibBottomActionBar>
    </BibPageShell>
  )
}

// ─── S07 — Secure Invite Opening ─────────────────────────────────────────────

function S07SecureInvite({ onNext }: { onNext: () => void }) {
  return (
    <BibPageShell web>
      <div className="flex-1 flex flex-col items-center justify-center px-6 py-12 gap-8">
        <BibBrandMark size={40} />

        {/* Skeleton mimicking S08 layout */}
        <div className="w-full max-w-[440px] flex flex-col gap-5" aria-hidden="true">
          {/* Creator intro skeleton */}
          <div className="flex flex-col gap-2">
            <div className="h-7 bg-subtle rounded-full w-[70%]" />
            <div className="h-4 bg-subtle rounded-full w-[55%]" />
          </div>

          {/* Summary card skeleton */}
          <div className="bg-surface rounded-[24px] p-5 shadow-[0_2px_16px_rgba(79,93,101,0.07)]">
            <div className="flex justify-between mb-4 gap-3">
              <div className="flex-1 flex flex-col gap-2">
                <div className="h-5 bg-subtle rounded-full w-[80%]" />
                <div className="h-6 bg-subtle rounded-full w-[50%]" />
              </div>
              <div className="h-7 w-20 bg-subtle rounded-full" />
            </div>
            <div className="h-16 bg-subtle rounded-[14px] mb-3" />
            <div className="h-3 bg-subtle rounded-full w-[60%]" />
          </div>

          {/* Vote options skeleton */}
          <div className="flex flex-col gap-2.5">
            {[0, 1, 2].map((i) => (
              <div key={i} className="h-[68px] bg-subtle rounded-[20px]" />
            ))}
          </div>
        </div>

        <div className="text-center">
          <p className="text-[16px] font-[600] text-text mb-1.5" role="status" aria-live="polite">
            Abrindo convite…
          </p>
          <p className="text-[13px] text-muted">Verificando acesso de forma segura</p>
        </div>

        {/* Dev shortcut for prototype */}
        <button
          onClick={onNext}
          className="text-[12px] text-muted/60 mt-4 hover:text-muted transition-colors"
        >
          (continuar na prévia)
        </button>
      </div>
    </BibPageShell>
  )
}

// ─── S08 — Voting Before Selection ───────────────────────────────────────────

function S08VotingBefore({ onNext, selectedVote, setSelectedVote }: {
  onNext: () => void
  selectedVote: 'buy' | 'wait' | 'skip' | null
  setSelectedVote: (v: 'buy' | 'wait' | 'skip') => void
}) {
  return (
    <BibPageShell web>
      <div className="flex-1 px-4 py-6 flex flex-col gap-5">
        {/* Brand */}
        <div className="flex items-center gap-2">
          <BibBrandMark size={24} />
          <span className="font-display text-[14px] font-[700] text-text">Before I Buy</span>
        </div>

        {/* Creator intro */}
        <div>
          <h1 className="font-display text-[24px] font-[700] text-text leading-tight mb-1.5">
            Lu quer sua perspectiva
          </h1>
          <p className="text-[14px] text-muted leading-relaxed">
            Você foi convidado a opinar sobre uma decisão de compra.
          </p>
        </div>

        {/* Dilemma */}
        <BibDilemmaSummary {...FIXTURE} remaining={FIXTURE.remaining} />

        {/* The question */}
        <div>
          <h2 className="font-display text-[18px] font-[700] text-text mb-3 leading-snug">
            O que a Lu provavelmente vai ficar feliz de ter feito?
          </h2>
          <div className="flex flex-col gap-2.5" role="radiogroup" aria-label="Escolha um palpite">
            <BibVoteOption type="buy" selected={selectedVote === 'buy'} onSelect={() => setSelectedVote('buy')} />
            <BibVoteOption type="wait" selected={selectedVote === 'wait'} onSelect={() => setSelectedVote('wait')} />
            <BibVoteOption type="skip" selected={selectedVote === 'skip'} onSelect={() => setSelectedVote('skip')} />
          </div>
        </div>

        <p className="text-[13px] text-muted text-center leading-relaxed">
          Seu palpite ajuda. A decisão final é da Lu.
        </p>

        <BibPrivacyNotice
          variant="neutral"
          title="Sem conta necessária"
          body="Você não precisa instalar o app, criar conta ou informar seu e-mail para votar."
        />
      </div>

      {selectedVote && (
        <BibBottomActionBar>
          <BibPrimaryButton onClick={onNext}>
            Enviar meu palpite
          </BibPrimaryButton>
        </BibBottomActionBar>
      )}
    </BibPageShell>
  )
}

// ─── S09 — Vote Selected ─────────────────────────────────────────────────────
// Reuses S08 layout with a pre-selected vote + visible CTA

function S09VoteSelected({ onNext, onBack, selectedVote, setSelectedVote }: {
  onNext: () => void
  onBack: () => void
  selectedVote: 'buy' | 'wait' | 'skip' | null
  setSelectedVote: (v: 'buy' | 'wait' | 'skip') => void
}) {
  const vote = selectedVote ?? 'wait'

  return (
    <BibPageShell web>
      <div className="flex-1 px-4 py-6 flex flex-col gap-5">
        <div className="flex items-center gap-2">
          <BibBrandMark size={24} />
          <span className="font-display text-[14px] font-[700] text-text">Before I Buy</span>
        </div>

        <div>
          <h1 className="font-display text-[24px] font-[700] text-text leading-tight mb-1.5">
            Lu quer sua perspectiva
          </h1>
          <p className="text-[14px] text-muted leading-relaxed">
            Você foi convidado a opinar sobre uma decisão de compra.
          </p>
        </div>

        <BibDilemmaSummary {...FIXTURE} remaining={FIXTURE.remaining} />

        <div>
          <h2 className="font-display text-[18px] font-[700] text-text mb-3 leading-snug">
            O que a Lu provavelmente vai ficar feliz de ter feito?
          </h2>
          <div className="flex flex-col gap-2.5" role="radiogroup" aria-label="Escolha um palpite">
            <BibVoteOption type="buy" selected={vote === 'buy'} onSelect={() => setSelectedVote('buy')} />
            <BibVoteOption type="wait" selected={vote === 'wait'} onSelect={() => setSelectedVote('wait')} />
            <BibVoteOption type="skip" selected={vote === 'skip'} onSelect={() => setSelectedVote('skip')} />
          </div>
        </div>

        <p className="text-[13px] text-muted text-center leading-relaxed">
          Toque em outra opção para mudar antes de enviar.
        </p>
      </div>

      <BibBottomActionBar>
        <BibPrimaryButton onClick={onNext}>
          Enviar meu palpite
        </BibPrimaryButton>
        <BibTextButton onClick={onBack}>Voltar</BibTextButton>
      </BibBottomActionBar>
    </BibPageShell>
  )
}

// ─── S10 — Vote Confirmed ─────────────────────────────────────────────────────

function S10VoteConfirmed({ onNext }: { onNext: () => void }) {
  return (
    <BibPageShell web>
      <div className="flex-1 flex flex-col items-center justify-center px-6 py-12 gap-6 text-center">
        <BibBrandMark size={36} />

        {/* Confirmation icon */}
        <div className="w-20 h-20 rounded-full bg-wait flex items-center justify-center shadow-[0_4px_24px_rgba(156,146,166,0.3)]">
          <svg width="36" height="36" viewBox="0 0 36 36" fill="none" aria-hidden="true">
            <path d="M8 18L15 25L28 12" stroke="#9C92A6" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </div>

        <div>
          <h1 className="font-display text-[26px] font-[700] text-text mb-2 leading-tight">
            Seu palpite entrou
          </h1>
          <p className="text-[15px] text-muted leading-relaxed max-w-[280px]">
            Você escolheu <strong className="text-text font-[600]">Esperar</strong>. Obrigado por ajudar a Lu a pensar com um pouco mais de espaço.
          </p>
        </div>

        <div className="w-full">
          <BibInlineMessage type="success">
            Seu palpite foi registrado com sucesso. Nenhuma conta foi criada.
          </BibInlineMessage>
        </div>

        <BibPrimaryButton onClick={onNext} fullWidth>
          Ver como o grupo respondeu
        </BibPrimaryButton>

        <p className="text-[12px] text-muted/70 leading-relaxed max-w-[240px]">
          Você não precisa de conta para ver os resultados.
        </p>
      </div>
    </BibPageShell>
  )
}

// ─── S11 — Aggregates After Voting ───────────────────────────────────────────

function S11Aggregates({ onBack }: { onBack: () => void }) {
  const total = FIXTURE.votes.buy + FIXTURE.votes.wait + FIXTURE.votes.skip

  return (
    <BibPageShell web>
      <div className="flex items-center gap-2.5 px-4 h-14 flex-shrink-0 border-b border-outline/20">
        <BibBrandMark size={24} />
        <span className="font-display text-[14px] font-[700] text-text">Before I Buy</span>
      </div>

      <div className="flex-1 px-4 py-5 flex flex-col gap-5">
        <div>
          <h1 className="font-display text-[24px] font-[700] text-text leading-tight mb-1.5">
            As perspectivas até agora
          </h1>
          <div className="flex items-center gap-2">
            <span className="text-[13px] text-muted">{total} palpites</span>
            <span aria-hidden="true" className="text-muted">·</span>
            <span className="text-[13px] text-muted">Pausa termina em 2 dias</span>
          </div>
        </div>

        {/* Distribution */}
        <div className="bg-surface rounded-[24px] p-5 shadow-[0_2px_16px_rgba(79,93,101,0.07)]">
          <BibVoteDistribution votes={FIXTURE.votes} total={total} myVote="wait" />
        </div>

        {/* User's own prediction */}
        <div className="bg-wait rounded-[20px] px-4 py-4 flex items-center gap-3">
          <div className="w-9 h-9 rounded-full bg-[#9C92A6]/30 flex items-center justify-center flex-shrink-0">
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
              <circle cx="8" cy="8" r="6.5" stroke="#9C92A6" strokeWidth="1.25" />
              <path d="M8 5V8.5l2 2" stroke="#9C92A6" strokeWidth="1.25" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </div>
          <div>
            <p className="text-[13px] font-[700] text-text">Seu palpite: Esperar</p>
            <p className="text-[12px] text-muted">Você pode mudar enquanto a pausa estiver aberta.</p>
          </div>
        </div>

        <BibPrivacyNotice
          variant="neutral"
          title="Perspectivas anônimas"
          body="Nomes, identidades e razões individuais não são exibidos. Você vê apenas a distribuição."
        />
      </div>

      <BibBottomActionBar>
        <BibTextButton onClick={onBack}>Alterar meu palpite</BibTextButton>
      </BibBottomActionBar>
    </BibPageShell>
  )
}

// ─── Navigation overlay ───────────────────────────────────────────────────────

function ScreenNav({
  current,
  total,
  onPrev,
  onNext,
  onGo,
}: {
  current: number
  total: number
  onPrev: () => void
  onNext: () => void
  onGo: (i: number) => void
}) {
  const screen = SCREENS[current]
  const isCreator = screen.flow === 'Criador'

  return (
    <div className="fixed top-0 left-0 right-0 z-50 bg-white/90 backdrop-blur-md border-b border-black/5 px-3 py-2.5 shadow-sm">
      <div className="max-w-[640px] mx-auto flex items-center gap-3">
        {/* Prev */}
        <button
          onClick={onPrev}
          disabled={current === 0}
          className="w-7 h-7 rounded-full flex items-center justify-center text-text hover:bg-subtle disabled:opacity-30 transition-all flex-shrink-0"
          aria-label="Tela anterior"
        >
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none" aria-hidden="true">
            <path d="M9 11L5 7L9 3" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>

        {/* Dots */}
        <div className="flex-1 flex items-center gap-1" role="tablist" aria-label="Telas">
          {SCREENS.map((s, i) => (
            <button
              key={i}
              role="tab"
              aria-selected={i === current}
              aria-label={`${s.id}: ${s.label}`}
              onClick={() => onGo(i)}
              className="flex-1 h-1.5 rounded-full transition-all duration-200"
              style={{
                backgroundColor: i === current
                  ? isCreator ? '#A94F38' : '#9C92A6'
                  : i < current ? (SCREENS[i].flow === 'Criador' ? '#A94F38' : '#9C92A6') + '55' : '#EFECE6',
              }}
            />
          ))}
        </div>

        {/* Next */}
        <button
          onClick={onNext}
          disabled={current === total - 1}
          className="w-7 h-7 rounded-full flex items-center justify-center text-text hover:bg-subtle disabled:opacity-30 transition-all flex-shrink-0"
          aria-label="Próxima tela"
        >
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none" aria-hidden="true">
            <path d="M5 3L9 7L5 11" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>

        {/* Label */}
        <div className="text-right flex-shrink-0 min-w-[80px]">
          <p className="text-[11px] font-[700] text-text">{screen.id}</p>
          <p className="text-[10px] text-muted">{screen.label}</p>
        </div>
      </div>

      {/* Flow badge */}
      <div className="max-w-[640px] mx-auto mt-1.5 flex items-center gap-2">
        <span
          className={`text-[10px] font-[700] px-2 py-0.5 rounded-full ${isCreator ? 'bg-action/10 text-action' : 'bg-wait text-[#6A5F7A]'}`}
        >
          {screen.flow}
        </span>
        <span className="text-[10px] text-muted">{screen.label}</span>
        <span className="text-[10px] text-muted ml-auto">{current + 1} / {total}</span>
      </div>
    </div>
  )
}

// ─── App ─────────────────────────────────────────────────────────────────────

export default function App() {
  const [screen, setScreen] = useState(0)
  const [selectedVote, setSelectedVote] = useState<'buy' | 'wait' | 'skip' | null>(null)

  const goTo = (i: number) => setScreen(Math.max(0, Math.min(SCREENS.length - 1, i)))
  const next = () => goTo(screen + 1)
  const prev = () => goTo(screen - 1)

  const renderScreen = () => {
    switch (screen) {
      case 0: return <S01EmptyHome onNext={next} />
      case 1: return <S02NewTemptation onNext={next} onBack={prev} />
      case 2: return <S03DilemmaReview onNext={next} onBack={prev} />
      case 3: return <S04GuestPreview onNext={next} onBack={prev} />
      case 4: return <S05PublishedShare onNext={next} onBack={prev} />
      case 5: return <S06ActiveDilemma onNext={next} onBack={prev} />
      case 6: return <S07SecureInvite onNext={next} />
      case 7: return (
        <S08VotingBefore
          onNext={next}
          selectedVote={selectedVote}
          setSelectedVote={(v) => { setSelectedVote(v); goTo(8) }}
        />
      )
      case 8: return (
        <S09VoteSelected
          onNext={next}
          onBack={prev}
          selectedVote={selectedVote ?? 'wait'}
          setSelectedVote={setSelectedVote}
        />
      )
      case 9: return <S10VoteConfirmed onNext={next} />
      case 10: return <S11Aggregates onBack={() => goTo(8)} />
      default: return null
    }
  }

  return (
    <div className="min-h-full bg-canvas">
      <ScreenNav
        current={screen}
        total={SCREENS.length}
        onPrev={prev}
        onNext={next}
        onGo={goTo}
      />
      {/* Offset for fixed nav (two rows ~68px) */}
      <div className="pt-[68px] min-h-full">
        {renderScreen()}
      </div>
    </div>
  )
}
