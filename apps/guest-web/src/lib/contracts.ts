export type Prediction = "buy" | "wait" | "skip";

export type Dilemma = {
  dilemmaId: string;
  ownerDisplayName: string;
  itemName: string;
  priceCents: number;
  currency: "BRL";
  category: string;
  purpose: "self" | "gift";
  reason: string;
  pauseDueAt: string;
};

export type Aggregates = Record<Prediction, number> & { total: number };

const predictions = new Set<Prediction>(["buy", "wait", "skip"]);

function isRecord(value: unknown): value is Record<string, unknown> {
  return Boolean(value) && typeof value === "object";
}

function isNonNegativeInteger(value: unknown): value is number {
  return Number.isSafeInteger(value) && (value as number) >= 0;
}

function isString(value: unknown): value is string {
  return typeof value === "string";
}

export function parseDilemmaResponse(value: unknown): Dilemma | null {
  if (!isRecord(value) || !isRecord(value.dilemma)) return null;
  const source = value.dilemma;
  if (!isString(source.dilemma_id) || !isString(source.owner_display_name) ||
    !isString(source.item_name) || !isString(source.currency) ||
    !isString(source.category) || !isString(source.purpose) ||
    !isString(source.reason) || !isString(source.pause_due_at)) return null;
  if (!isNonNegativeInteger(source.price_cents)) {
    return null;
  }
  if (source.currency !== "BRL" || (source.purpose !== "self" && source.purpose !== "gift")) {
    return null;
  }
  return {
    dilemmaId: source.dilemma_id,
    ownerDisplayName: source.owner_display_name,
    itemName: source.item_name,
    priceCents: source.price_cents,
    currency: source.currency,
    category: source.category,
    purpose: source.purpose,
    reason: source.reason,
    pauseDueAt: source.pause_due_at,
  };
}

export function parseVoteResponse(value: unknown):
  | { prediction: Prediction; aggregates: Aggregates }
  | null {
  if (!isRecord(value) || !isRecord(value.vote) || !isRecord(value.aggregates)) {
    return null;
  }
  const { prediction } = value.vote;
  const { buy, wait, skip, total } = value.aggregates;
  if (!predictions.has(prediction as Prediction)) return null;
  if (!isNonNegativeInteger(buy) || !isNonNegativeInteger(wait) ||
    !isNonNegativeInteger(skip) || !isNonNegativeInteger(total)) {
    return null;
  }
  if (buy + wait + skip !== total) return null;
  return {
    prediction: prediction as Prediction,
    aggregates: { buy, wait, skip, total },
  };
}
