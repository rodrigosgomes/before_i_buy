import React from 'react'

// ─── Icons ───────────────────────────────────────────────────────────────────

export const IconLock = ({ size = 16, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none" className={className} aria-hidden="true">
    <path d="M5 7V5a3 3 0 0 1 6 0v2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    <rect x="3" y="7" width="10" height="8" rx="2" stroke="currentColor" strokeWidth="1.5" />
    <circle cx="8" cy="11.5" r="1.5" fill="currentColor" />
  </svg>
)

export const IconChevronLeft = ({ size = 20 }: { size?: number }) => (
  <svg width={size} height={size} viewBox="0 0 20 20" fill="none" aria-hidden="true">
    <path d="M13 16L7 10L13 4" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
)

export const IconShare = ({ size = 20 }: { size?: number }) => (
  <svg width={size} height={size} viewBox="0 0 20 20" fill="none" aria-hidden="true">
    <path d="M4 10v6a1 1 0 0 0 1 1h10a1 1 0 0 0 1-1v-6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    <path d="M10 13V3m-3 3 3-3 3 3" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
)

export const IconBag = ({ size = 20, filled = false }: { size?: number; filled?: boolean }) => (
  <svg width={size} height={size} viewBox="0 0 20 20" fill="none" aria-hidden="true">
    <path d="M6 7V5a4 4 0 0 1 8 0v2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    <rect x="3" y="7" width="14" height="10" rx="3" stroke="currentColor" strokeWidth="1.5" fill={filled ? 'currentColor' : 'none'} fillOpacity={filled ? 0.2 : 0} />
  </svg>
)

export const IconClock = ({ size = 20, filled = false }: { size?: number; filled?: boolean }) => (
  <svg width={size} height={size} viewBox="0 0 20 20" fill="none" aria-hidden="true">
    <circle cx="10" cy="10" r="7.5" stroke="currentColor" strokeWidth="1.5" fill={filled ? 'currentColor' : 'none'} fillOpacity={filled ? 0.2 : 0} />
    <path d="M10 6.5V10l2.5 2.5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
)

export const IconLeaf = ({ size = 20, filled = false }: { size?: number; filled?: boolean }) => (
  <svg width={size} height={size} viewBox="0 0 20 20" fill="none" aria-hidden="true">
    <path d="M5 15C5 15 5 8 12 5c4-1.5 6-1 6-1s0 4-3 7c-2.5 2.5-6 3-6 3H5Z" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" fill={filled ? 'currentColor' : 'none'} fillOpacity={filled ? 0.2 : 0} />
    <path d="M5 15C6.5 13.5 9 11 12 8" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
  </svg>
)

export const IconCheck = ({ size = 16 }: { size?: number }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none" aria-hidden="true">
    <path d="M3 8L6.5 11.5L13 5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
)

export const IconAlert = ({ size = 15, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none" className={className} aria-hidden="true">
    <path d="M8 2L15 14H1L8 2Z" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
    <path d="M8 7V9.5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    <circle cx="8" cy="11.5" r="0.75" fill="currentColor" />
  </svg>
)

export const IconInfo = ({ size = 15, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none" className={className} aria-hidden="true">
    <circle cx="8" cy="8" r="6.5" stroke="currentColor" strokeWidth="1.25" />
    <path d="M8 7V11" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    <circle cx="8" cy="5" r="0.75" fill="currentColor" />
  </svg>
)

export const IconEye = ({ size = 13, className = '' }: { size?: number; className?: string }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none" className={className} aria-hidden="true">
    <path d="M1 8s2.5-5 7-5 7 5 7 5-2.5 5-7 5-7-5-7-5Z" stroke="currentColor" strokeWidth="1.25" />
    <circle cx="8" cy="8" r="2" fill="currentColor" fillOpacity="0.45" />
  </svg>
)

export const IconStar = ({ size = 20 }: { size?: number }) => (
  <svg width={size} height={size} viewBox="0 0 20 20" fill="none" aria-hidden="true">
    <path d="M10 2l2.4 5 5.6.8-4 3.9.9 5.3L10 14.5l-4.9 2.5.9-5.3L2 7.8l5.6-.8L10 2Z" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
  </svg>
)

export const IconForward = ({ size = 16 }: { size?: number }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none" aria-hidden="true">
    <path d="M3 8h10m-4-4 4 4-4 4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
)

// ─── Brand Mark ──────────────────────────────────────────────────────────────

export const BibBrandMark = ({ size = 32 }: { size?: number }) => (
  <svg width={size} height={size} viewBox="0 0 32 32" fill="none" role="img" aria-label="Before I Buy">
    <rect width="32" height="32" rx="10" fill="#EFECE6" />
    <rect x="9" y="9" width="6" height="14" rx="3" fill="#C56C51" />
    <rect x="17" y="9" width="6" height="14" rx="3" fill="#C56C51" fillOpacity="0.42" />
  </svg>
)

// ─── Page Shell ──────────────────────────────────────────────────────────────

export const BibPageShell = ({
  children,
  className = '',
  web = false,
}: {
  children: React.ReactNode
  className?: string
  web?: boolean
}) => (
  <div className={`bg-canvas min-h-full w-full ${web ? 'max-w-[640px]' : 'max-w-[393px]'} mx-auto flex flex-col ${className}`}>
    {children}
  </div>
)

// ─── Top Bar ─────────────────────────────────────────────────────────────────

export const BibTopBar = ({
  title,
  subtitle,
  onBack,
  rightAction,
  brandMark = false,
}: {
  title?: string
  subtitle?: string
  onBack?: () => void
  rightAction?: React.ReactNode
  brandMark?: boolean
}) => (
  <header className="flex items-center gap-3 px-4 h-14 bg-canvas flex-shrink-0">
    {onBack ? (
      <button
        onClick={onBack}
        className="w-10 h-10 flex items-center justify-center rounded-full text-text hover:bg-subtle transition-colors flex-shrink-0"
        aria-label="Voltar"
      >
        <IconChevronLeft size={20} />
      </button>
    ) : brandMark ? (
      <BibBrandMark size={28} />
    ) : (
      <div className="w-10" />
    )}
    <div className="flex-1 min-w-0">
      {title && (
        <h1 className="font-display text-[18px] font-[700] leading-[24px] text-text truncate">{title}</h1>
      )}
      {subtitle && (
        <p className="text-[11px] text-muted font-[500] mt-0.5">{subtitle}</p>
      )}
    </div>
    {rightAction ?? <div className="w-10" />}
  </header>
)

// ─── Draft Banner ─────────────────────────────────────────────────────────────

export const BibDraftBanner = ({ recovered = false }: { recovered?: boolean }) => (
  <div className="mx-4 mb-3 bg-warning rounded-[16px] px-4 py-3 flex items-start gap-2.5" role="status">
    <span className="text-[#8F6A0A] mt-0.5 flex-shrink-0">
      <IconAlert size={14} />
    </span>
    <div>
      <p className="text-[13px] font-[700] text-[#5C4500]">Rascunho — não compartilhado</p>
      {recovered && (
        <p className="text-[12px] text-[#7A5A00] mt-0.5 leading-relaxed">
          Recuperamos seu rascunho. Revise antes de publicar.
        </p>
      )}
    </div>
  </div>
)

// ─── Primary Button ───────────────────────────────────────────────────────────

export const BibPrimaryButton = ({
  children,
  onClick,
  disabled = false,
  loading = false,
  fullWidth = true,
  icon,
}: {
  children: React.ReactNode
  onClick?: () => void
  disabled?: boolean
  loading?: boolean
  fullWidth?: boolean
  icon?: React.ReactNode
}) => (
  <button
    onClick={onClick}
    disabled={disabled || loading}
    className={`
      ${fullWidth ? 'w-full' : 'px-8'}
      h-[52px] rounded-[20px] bg-action text-white font-[600] text-[16px]
      flex items-center justify-center gap-2.5
      transition-all duration-200
      hover:bg-action-pressed active:scale-[0.98]
      disabled:opacity-40 disabled:cursor-not-allowed
      focus-visible:outline-2 focus-visible:outline-focus focus-visible:outline-offset-2
    `}
  >
    {loading ? (
      <span className="w-5 h-5 border-2 border-white/40 border-t-white rounded-full animate-spin" />
    ) : (
      <>
        {icon && <span className="flex-shrink-0">{icon}</span>}
        {children}
      </>
    )}
  </button>
)

// ─── Secondary Button ─────────────────────────────────────────────────────────

export const BibSecondaryButton = ({
  children,
  onClick,
  fullWidth = true,
}: {
  children: React.ReactNode
  onClick?: () => void
  fullWidth?: boolean
}) => (
  <button
    onClick={onClick}
    className={`
      ${fullWidth ? 'w-full' : 'px-8'}
      h-[52px] rounded-[20px] border-[1.5px] border-action text-action font-[600] text-[16px]
      flex items-center justify-center gap-2.5
      transition-all duration-200
      hover:bg-action/6 active:bg-action/12 active:scale-[0.98]
      focus-visible:outline-2 focus-visible:outline-focus focus-visible:outline-offset-2
    `}
  >
    {children}
  </button>
)

// ─── Text Button ──────────────────────────────────────────────────────────────

export const BibTextButton = ({
  children,
  onClick,
  center = true,
}: {
  children: React.ReactNode
  onClick?: () => void
  center?: boolean
}) => (
  <button
    onClick={onClick}
    className={`min-h-[48px] px-4 text-[15px] font-[500] text-muted transition-colors hover:text-text flex items-center gap-1.5 ${center ? 'justify-center w-full' : ''}`}
  >
    {children}
  </button>
)

// ─── Bottom Action Bar ────────────────────────────────────────────────────────

export const BibBottomActionBar = ({ children }: { children: React.ReactNode }) => (
  <div className="sticky bottom-0 bg-canvas/95 backdrop-blur-sm border-t border-outline/25 px-4 py-4 flex flex-col gap-2 mt-auto">
    {children}
  </div>
)

// ─── Text Field ───────────────────────────────────────────────────────────────

export const BibTextField = ({
  label,
  value,
  onChange,
  helper,
  counter,
  maxLength,
  error,
  multiline = false,
  rows = 5,
  placeholder,
}: {
  label: string
  value: string
  onChange: (v: string) => void
  helper?: string
  counter?: boolean
  maxLength?: number
  error?: string
  multiline?: boolean
  rows?: number
  placeholder?: string
}) => {
  const id = `field-${label.toLowerCase().replace(/\s+/g, '-')}`
  const hasError = !!error

  return (
    <div className="flex flex-col gap-1.5">
      <label htmlFor={id} className="text-[14px] font-[600] text-text">
        {label}
      </label>
      {multiline ? (
        <textarea
          id={id}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          maxLength={maxLength}
          rows={rows}
          placeholder={placeholder}
          className={`w-full px-4 py-3.5 rounded-[16px] bg-surface border text-[16px] text-text leading-relaxed placeholder:text-muted/45 resize-none focus:outline-2 focus:outline-focus focus:outline-offset-1 transition-colors ${hasError ? 'border-err' : 'border-outline focus:border-text/60'}`}
        />
      ) : (
        <input
          id={id}
          type="text"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          maxLength={maxLength}
          placeholder={placeholder}
          className={`w-full h-[52px] px-4 rounded-[16px] bg-surface border text-[16px] text-text placeholder:text-muted/45 focus:outline-2 focus:outline-focus focus:outline-offset-1 transition-colors ${hasError ? 'border-err' : 'border-outline focus:border-text/60'}`}
        />
      )}
      <div className="flex items-start justify-between gap-2">
        {(helper || hasError) && (
          <span className={`text-[12px] leading-relaxed ${hasError ? 'text-err' : 'text-muted'}`}>
            {error ?? helper}
          </span>
        )}
        {counter && maxLength !== undefined && (
          <span className="text-[12px] text-muted ml-auto flex-shrink-0">
            {value.length}/{maxLength}
          </span>
        )}
      </div>
    </div>
  )
}

// ─── Currency Field ───────────────────────────────────────────────────────────

export const BibCurrencyField = ({
  value,
  onChange,
  error,
}: {
  value: string
  onChange: (v: string) => void
  error?: string
}) => (
  <div className="flex flex-col gap-1.5">
    <label htmlFor="bib-currency" className="text-[14px] font-[600] text-text">
      Preço
    </label>
    <div
      className={`flex items-center gap-2 bg-surface border rounded-[16px] px-4 h-[52px] transition-colors focus-within:border-text/60 focus-within:outline-2 focus-within:outline-focus focus-within:outline-offset-1 ${error ? 'border-err' : 'border-outline'}`}
    >
      <span className="text-[16px] font-[600] text-muted select-none">R$</span>
      <input
        id="bib-currency"
        type="text"
        inputMode="decimal"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder="0,00"
        className="flex-1 bg-transparent text-[16px] text-text placeholder:text-muted/45 focus:outline-none"
      />
    </div>
    {error && <span className="text-[12px] text-err">{error}</span>}
  </div>
)

// ─── Select Field ─────────────────────────────────────────────────────────────

export const BibSelectField = ({
  label,
  value,
  onChange,
  options,
}: {
  label: string
  value: string
  onChange: (v: string) => void
  options: string[]
}) => {
  const id = `select-${label.toLowerCase().replace(/\s+/g, '-')}`
  return (
    <div className="flex flex-col gap-1.5">
      <label htmlFor={id} className="text-[14px] font-[600] text-text">
        {label}
      </label>
      <div className="relative">
        <select
          id={id}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="w-full h-[52px] px-4 pr-10 rounded-[16px] bg-surface border border-outline text-[16px] text-text focus:outline-2 focus:outline-focus focus:outline-offset-1 transition-colors appearance-none cursor-pointer"
        >
          {options.map((o) => (
            <option key={o} value={o}>
              {o}
            </option>
          ))}
        </select>
        <span className="absolute right-4 top-1/2 -translate-y-1/2 text-muted pointer-events-none">
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
            <path d="M4 6l4 4 4-4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </span>
      </div>
    </div>
  )
}

// ─── Segmented Choice ─────────────────────────────────────────────────────────

export const BibSegmentedChoice = ({
  label,
  options,
  value,
  onChange,
}: {
  label: string
  options: { value: string; label: string; sub?: string }[]
  value: string
  onChange: (v: string) => void
}) => (
  <fieldset className="flex flex-col gap-2 border-0 p-0 m-0">
    <legend className="text-[14px] font-[600] text-text mb-0.5">{label}</legend>
    {options.map((opt) => {
      const selected = value === opt.value
      return (
        <button
          key={opt.value}
          type="button"
          role="radio"
          aria-checked={selected}
          onClick={() => onChange(opt.value)}
          className={`w-full min-h-[52px] px-4 py-3 rounded-[16px] border-[1.5px] text-left flex items-center gap-3 transition-all duration-150 focus-visible:outline-2 focus-visible:outline-focus focus-visible:outline-offset-1 ${selected ? 'bg-action/8 border-action' : 'bg-surface border-outline hover:border-muted'}`}
        >
          <div
            className={`w-4 h-4 rounded-full border-[2px] flex items-center justify-center flex-shrink-0 transition-all ${selected ? 'border-action bg-action' : 'border-outline'}`}
          >
            {selected && <div className="w-1.5 h-1.5 bg-white rounded-full" />}
          </div>
          <div>
            <p className={`text-[15px] font-[500] transition-colors ${selected ? 'text-action' : 'text-text'}`}>
              {opt.label}
            </p>
            {opt.sub && <p className="text-[12px] text-muted">{opt.sub}</p>}
          </div>
        </button>
      )
    })}
  </fieldset>
)

// ─── Privacy Notice ───────────────────────────────────────────────────────────

export const BibPrivacyNotice = ({
  variant = 'neutral',
  title,
  body,
}: {
  variant?: 'neutral' | 'attention'
  title: string
  body: string
}) => (
  <div
    className={`flex gap-3 p-4 rounded-[16px] ${variant === 'attention' ? 'bg-warning' : 'bg-info'}`}
    role="note"
  >
    <span
      className={`mt-0.5 flex-shrink-0 ${variant === 'attention' ? 'text-[#8F6A0A]' : 'text-[#245E73]'}`}
    >
      {variant === 'attention' ? <IconAlert size={15} /> : <IconLock size={15} />}
    </span>
    <div>
      <p className="text-[13px] font-[700] text-text">{title}</p>
      <p className="text-[12px] text-muted mt-0.5 leading-relaxed">{body}</p>
    </div>
  </div>
)

// ─── Dilemma Summary ─────────────────────────────────────────────────────────

export const BibDilemmaSummary = ({
  itemName = 'Fone com cancelamento de ruído',
  price = 'R$ 2.400,00',
  category = 'Tecnologia',
  reason = 'Quero mais foco para trabalhar e viajar com menos ruído.',
  purpose = 'Para mim',
  pause = '3 dias',
  remaining,
  compact = false,
}: {
  itemName?: string
  price?: string
  category?: string
  reason?: string
  purpose?: string
  pause?: string
  remaining?: string
  compact?: boolean
}) => (
  <article className="bg-surface rounded-[24px] p-5 shadow-[0_2px_20px_rgba(79,93,101,0.08)]">
    <div className="flex items-start justify-between gap-3 mb-3.5">
      <div className="flex-1 min-w-0">
        <p className="font-display text-[19px] font-[700] text-text leading-snug">{itemName}</p>
        <p className="text-[22px] font-[700] text-action mt-1 font-display">{price}</p>
      </div>
      <span className="flex-shrink-0 text-[12px] font-[600] text-muted bg-subtle px-3 py-1.5 rounded-full">
        {category}
      </span>
    </div>
    {!compact && (
      <div className="bg-canvas rounded-[16px] px-4 py-3.5 mb-3.5 border border-outline/20">
        <p className="text-[11px] font-[700] text-muted uppercase tracking-widest mb-1.5">Por que agora</p>
        <p className="text-[14px] text-text leading-relaxed italic">"{reason}"</p>
      </div>
    )}
    <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-[12px] text-muted font-[500]">
      <span>{purpose}</span>
      <span aria-hidden="true">·</span>
      <span>Pausa de {pause}</span>
      {remaining && (
        <>
          <span aria-hidden="true">·</span>
          <span>Termina em {remaining}</span>
        </>
      )}
    </div>
  </article>
)

// ─── Status Chip ─────────────────────────────────────────────────────────────

export const BibStatusChip = ({
  label,
  type = 'neutral',
}: {
  label: string
  type?: 'neutral' | 'active' | 'warning' | 'success'
}) => {
  const styles: Record<string, string> = {
    neutral: 'bg-subtle text-muted',
    active: 'bg-buy text-[#1E5A50]',
    success: 'bg-buy text-[#1E5A50]',
    warning: 'bg-warning text-[#8F6A0A]',
  }
  const dotColors: Record<string, string> = {
    neutral: 'bg-muted',
    active: 'bg-[#2D7A6A]',
    success: 'bg-[#2D7A6A]',
    warning: 'bg-[#8F6A0A]',
  }
  return (
    <span className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-[12px] font-[700] ${styles[type]}`}>
      <span className={`w-1.5 h-1.5 rounded-full ${dotColors[type]}`} aria-hidden="true" />
      {label}
    </span>
  )
}

// ─── Empty State ──────────────────────────────────────────────────────────────

export const BibEmptyState = ({
  title,
  body,
  illustration,
}: {
  title: string
  body: string
  illustration?: React.ReactNode
}) => (
  <div className="flex flex-col items-center text-center px-6 py-8">
    {illustration ?? (
      <div className="w-20 h-20 rounded-full bg-subtle flex items-center justify-center mb-5">
        <svg width="32" height="32" viewBox="0 0 32 32" fill="none" aria-hidden="true">
          <circle cx="16" cy="16" r="13" stroke="#C8C3BC" strokeWidth="1.5" />
          <path d="M11 16a5 5 0 0 1 10 0" stroke="#C8C3BC" strokeWidth="1.5" strokeLinecap="round" />
          <circle cx="12" cy="13" r="1.5" fill="#C8C3BC" />
          <circle cx="20" cy="13" r="1.5" fill="#C8C3BC" />
        </svg>
      </div>
    )}
    <p className="font-display text-[18px] font-[700] text-text mb-2">{title}</p>
    <p className="text-[14px] text-muted leading-relaxed">{body}</p>
  </div>
)

// ─── Vote Option ─────────────────────────────────────────────────────────────

type VoteType = 'buy' | 'wait' | 'skip'

const VOTE_CONFIG: Record<VoteType, {
  label: string
  sublabel: string
  container: string
  borderSelected: string
  iconBgSelected: string
  iconColor: string
  chipBg: string
  chipText: string
  Icon: React.ComponentType<{ size?: number; filled?: boolean }>
}> = {
  buy: {
    label: 'Comprar',
    sublabel: 'provavelmente vai ficar feliz',
    container: '#DCEAE5',
    borderSelected: '#89AFA3',
    iconBgSelected: '#89AFA3',
    iconColor: '#2D7A6A',
    chipBg: '#BDD8D0',
    chipText: '#1E5A50',
    Icon: IconBag,
  },
  wait: {
    label: 'Esperar',
    sublabel: 'ainda é cedo',
    container: '#E8E3EC',
    borderSelected: '#9C92A6',
    iconBgSelected: '#9C92A6',
    iconColor: '#6A5F7A',
    chipBg: '#C9C0D4',
    chipText: '#4A3F5A',
    Icon: IconClock,
  },
  skip: {
    label: 'Deixar pra lá',
    sublabel: 'provavelmente vai ficar feliz',
    container: '#E9E0D5',
    borderSelected: '#CBBCA9',
    iconBgSelected: '#CBBCA9',
    iconColor: '#7A6555',
    chipBg: '#D4C7B5',
    chipText: '#5A4535',
    Icon: IconLeaf,
  },
}

export const BibVoteOption = ({
  type,
  selected = false,
  onSelect,
  disabled = false,
}: {
  type: VoteType
  selected?: boolean
  onSelect?: () => void
  disabled?: boolean
}) => {
  const cfg = VOTE_CONFIG[type]
  return (
    <button
      role="radio"
      aria-checked={selected}
      onClick={!disabled ? onSelect : undefined}
      disabled={disabled}
      style={{
        backgroundColor: selected ? cfg.container : '#FFFFFF',
        borderColor: selected ? cfg.borderSelected : '#C8C3BC',
        transform: selected ? 'scale(1.02)' : 'scale(1)',
      }}
      className={`w-full p-4 rounded-[20px] border-[2px] text-left transition-all duration-200 focus-visible:outline-2 focus-visible:outline-[#245E73] focus-visible:outline-offset-2 ${disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}`}
    >
      <div className="flex items-center gap-3">
        <div
          className="w-11 h-11 rounded-full flex items-center justify-center flex-shrink-0 transition-all"
          style={{
            backgroundColor: selected ? cfg.iconBgSelected : cfg.container,
            color: selected ? '#fff' : cfg.iconColor,
          }}
        >
          <cfg.Icon size={20} filled={selected} />
        </div>
        <div className="flex-1 min-w-0">
          <p className="font-[600] text-[15px] text-text">{cfg.label}</p>
          <p className="text-[12px] text-muted">{cfg.sublabel}</p>
        </div>
        {selected && (
          <span
            className="flex-shrink-0 text-[11px] font-[700] px-2.5 py-1 rounded-full whitespace-nowrap"
            style={{ backgroundColor: cfg.chipBg, color: cfg.chipText }}
          >
            Meu palpite
          </span>
        )}
      </div>
    </button>
  )
}

// ─── Vote Distribution ────────────────────────────────────────────────────────

export const BibVoteDistribution = ({
  votes,
  total,
  myVote,
}: {
  votes: { buy: number; wait: number; skip: number }
  total: number
  myVote?: VoteType
}) => {
  const entries: Array<{ key: VoteType; label: string; barColor: string }> = [
    { key: 'buy', label: 'Comprar', barColor: '#89AFA3' },
    { key: 'wait', label: 'Esperar', barColor: '#9C92A6' },
    { key: 'skip', label: 'Deixar pra lá', barColor: '#CBBCA9' },
  ]
  return (
    <div className="flex flex-col gap-4" role="list" aria-label="Distribuição de palpites">
      {entries.map(({ key, label, barColor }) => {
        const count = votes[key]
        const pct = total > 0 ? Math.round((count / total) * 100) : 0
        const isMine = myVote === key
        return (
          <div key={key} role="listitem">
            <div className="flex items-baseline justify-between mb-2">
              <span className={`text-[14px] leading-tight ${isMine ? 'font-[700] text-text' : 'font-[500] text-muted'}`}>
                {label}
                {isMine && (
                  <span className="text-[12px] font-[500] text-muted ml-1.5">· seu palpite</span>
                )}
              </span>
              <span className="text-[13px] font-[600] text-text tabular-nums">
                {count} palpite{count !== 1 ? 's' : ''} · {pct}%
              </span>
            </div>
            <div className="h-3 bg-subtle rounded-full overflow-hidden">
              <div
                className="h-full rounded-full transition-all duration-700"
                style={{ width: `${Math.max(pct, 3)}%`, backgroundColor: barColor }}
                role="meter"
                aria-label={`${label}: ${pct}%`}
                aria-valuenow={pct}
                aria-valuemin={0}
                aria-valuemax={100}
              />
            </div>
          </div>
        )
      })}
    </div>
  )
}

// ─── Loading Block ────────────────────────────────────────────────────────────

export const BibLoadingBlock = ({
  lines = 3,
  className = '',
  height = 'h-4',
}: {
  lines?: number
  className?: string
  height?: string
}) => (
  <div className={`animate-pulse flex flex-col gap-3 ${className}`} aria-hidden="true">
    {Array.from({ length: lines }).map((_, i) => (
      <div
        key={i}
        className={`${height} bg-subtle rounded-full`}
        style={{ width: `${[92, 68, 80, 58, 75][i % 5]}%` }}
      />
    ))}
  </div>
)

// ─── Inline Message ───────────────────────────────────────────────────────────

export const BibInlineMessage = ({
  type = 'info',
  children,
}: {
  type?: 'info' | 'success' | 'warning' | 'error'
  children: React.ReactNode
}) => {
  const styles: Record<string, { bg: string; textColor: string; icon: React.ReactNode }> = {
    info: { bg: 'bg-info', textColor: 'text-[#245E73]', icon: <IconInfo size={15} /> },
    success: { bg: 'bg-buy', textColor: 'text-[#1E5A50]', icon: <IconCheck size={14} /> },
    warning: { bg: 'bg-warning', textColor: 'text-[#8F6A0A]', icon: <IconAlert size={14} /> },
    error: { bg: 'bg-err/10', textColor: 'text-err', icon: <IconAlert size={14} /> },
  }
  const s = styles[type]
  return (
    <div className={`flex items-start gap-3 p-4 rounded-[16px] ${s.bg}`} role="alert">
      <span className={`mt-0.5 flex-shrink-0 ${s.textColor}`}>{s.icon}</span>
      <p className={`text-[13px] font-[500] leading-relaxed ${s.textColor}`}>{children}</p>
    </div>
  )
}

// ─── Guest Preview Frame ──────────────────────────────────────────────────────

export const BibGuestPreviewFrame = ({ children }: { children: React.ReactNode }) => (
  <div className="mx-4 rounded-[20px] overflow-hidden border-[1.5px] border-outline/40 shadow-[0_4px_28px_rgba(79,93,101,0.13)]">
    <div className="bg-subtle px-3 py-2.5 flex items-center gap-2 border-b border-outline/20">
      <div className="flex gap-1">
        <div className="w-2.5 h-2.5 rounded-full bg-outline/60" />
        <div className="w-2.5 h-2.5 rounded-full bg-outline/60" />
        <div className="w-2.5 h-2.5 rounded-full bg-outline/60" />
      </div>
      <div className="flex-1 bg-surface rounded-full px-3 py-1 flex items-center gap-1.5">
        <IconLock size={9} className="text-muted/70" />
        <span className="text-[10px] text-muted font-[500] truncate">beforeibuy.app/c/···</span>
      </div>
    </div>
    <div className="bg-warning/70 px-4 py-2 flex items-center gap-2 border-b border-outline/20">
      <IconEye size={12} className="text-[#8F6A0A]" />
      <span className="text-[11px] font-[700] text-[#5C4500]">Prévia — nenhuma ação será enviada</span>
    </div>
    <div className="bg-canvas max-h-[400px] overflow-y-auto">{children}</div>
  </div>
)
