import type { Aggregates, Dilemma, Prediction } from "./contracts";

export type VoteState =
  | { status: "opening" }
  | { status: "unavailable"; retryable: boolean }
  | { status: "voting"; dilemma: Dilemma; selected?: Prediction; sending: boolean }
  | { status: "confirmed"; dilemma: Dilemma; prediction: Prediction; aggregates: Aggregates }
  | { status: "aggregates"; dilemma: Dilemma; prediction: Prediction; aggregates: Aggregates };

export type VoteAction =
  | { type: "opened"; dilemma: Dilemma }
  | { type: "unavailable"; retryable?: boolean }
  | { type: "select"; prediction: Prediction }
  | { type: "sending" }
  | { type: "submitted"; prediction: Prediction; aggregates: Aggregates }
  | { type: "showAggregates" }
  | { type: "changeVote" };

export const initialVoteState: VoteState = { status: "opening" };

export function voteReducer(state: VoteState, action: VoteAction): VoteState {
  switch (action.type) {
    case "opened":
      return { status: "voting", dilemma: action.dilemma, sending: false };
    case "unavailable":
      if (state.status === "voting") return { ...state, sending: false };
      return { status: "unavailable", retryable: action.retryable ?? true };
    case "select":
      return state.status === "voting" && !state.sending
        ? { ...state, selected: action.prediction }
        : state;
    case "sending":
      return state.status === "voting" && state.selected
        ? { ...state, sending: true }
        : state;
    case "submitted":
      return state.status === "voting"
        ? { status: "confirmed", dilemma: state.dilemma, prediction: action.prediction, aggregates: action.aggregates }
        : state;
    case "showAggregates":
      return state.status === "confirmed" ? { ...state, status: "aggregates" } : state;
    case "changeVote":
      return state.status === "aggregates"
        ? { status: "voting", dilemma: state.dilemma, selected: state.prediction, sending: false }
        : state;
  }
}
