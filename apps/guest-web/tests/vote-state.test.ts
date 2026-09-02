import type { Dilemma } from "../src/lib/contracts";
import { initialVoteState, voteReducer } from "../src/lib/vote-state";

const dilemma: Dilemma = { dilemmaId: "11111111-1111-4111-8111-111111111111", ownerDisplayName: "Lu", itemName: "Fone", priceCents: 240000, currency: "BRL", category: "Tecnologia", purpose: "self", reason: "Mais foco", pauseDueAt: "2026-09-04T00:00:00.000Z" };
const aggregates = { buy: 1, wait: 2, skip: 0, total: 3 };

describe("vote state", () => {
  it("does not disclose aggregates before a successful submission", () => {
    const opened = voteReducer(initialVoteState, { type: "opened", dilemma });
    const selected = voteReducer(opened, { type: "select", prediction: "wait" });
    const sending = voteReducer(selected, { type: "sending" });
    expect(sending).toMatchObject({ status: "voting", selected: "wait", sending: true });
    const confirmed = voteReducer(sending, { type: "submitted", prediction: "wait", aggregates });
    expect(confirmed.status).toBe("confirmed");
    const aggregateState = voteReducer(confirmed, { type: "showAggregates" });
    expect(aggregateState).toMatchObject({ status: "aggregates", aggregates });
    expect(voteReducer(aggregateState, { type: "changeVote" })).toMatchObject({ status: "voting", selected: "wait", sending: false });
  });

  it("preserves an unsent selection after a recoverable failure and rejects invalid transitions", () => {
    const selected = voteReducer(voteReducer(voteReducer(initialVoteState, { type: "opened", dilemma }), { type: "select", prediction: "buy" }), { type: "sending" });
    expect(voteReducer(selected, { type: "unavailable" })).toMatchObject({ status: "voting", selected: "buy", sending: false });
    expect(voteReducer(initialVoteState, { type: "sending" })).toEqual(initialVoteState);
  });
});
