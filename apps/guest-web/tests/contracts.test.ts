import { parseDilemmaResponse, parseVoteResponse } from "../src/lib/contracts";

const dilemma = {
  dilemma: {
    dilemma_id: "11111111-1111-4111-8111-111111111111",
    owner_display_name: "Lu",
    item_name: "Fone",
    price_cents: 240000,
    currency: "BRL",
    category: "Tecnologia",
    purpose: "self",
    reason: "Quero mais foco para trabalhar.",
    pause_due_at: "2026-09-04T00:00:00.000Z",
  },
};

describe("guest contracts", () => {
  it("accepts only the allowlisted invite fields", () => {
    expect(parseDilemmaResponse(dilemma)?.ownerDisplayName).toBe("Lu");
    expect(parseDilemmaResponse({ dilemma: { ...dilemma.dilemma, currency: "USD" } })).toBeNull();
    expect(parseDilemmaResponse({ dilemma: { ...dilemma.dilemma, price_cents: -1 } })).toBeNull();
  });

  it("rejects malformed or inconsistent vote aggregates", () => {
    expect(parseVoteResponse({ vote: { prediction: "wait" }, aggregates: { buy: 1, wait: 2, skip: 0, total: 3 } })).toEqual({ prediction: "wait", aggregates: { buy: 1, wait: 2, skip: 0, total: 3 } });
    expect(parseVoteResponse({ vote: { prediction: "other" }, aggregates: { buy: 1, wait: 2, skip: 0, total: 3 } })).toBeNull();
    expect(parseVoteResponse({ vote: { prediction: "wait" }, aggregates: { buy: 1, wait: 2, skip: 0, total: 2 } })).toBeNull();
  });
});
