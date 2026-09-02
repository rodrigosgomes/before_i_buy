"use client";

import React, { useEffect, useReducer } from "react";

import { parseDilemmaResponse, parseVoteResponse, type Aggregates, type Prediction } from "../lib/contracts";
import { initialVoteState, voteReducer } from "../lib/vote-state";

const options: Array<{ value: Prediction; title: string; detail: string }> = [
  { value: "buy", title: "Comprar", detail: "Provavelmente vai ficar feliz" },
  { value: "wait", title: "Esperar", detail: "Ainda é cedo" },
  { value: "skip", title: "Deixar pra lá", detail: "Provavelmente vai ficar feliz" },
];

function price(cents: number) {
  return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(cents / 100);
}

function predictionLabel(prediction: Prediction) {
  return options.find((option) => option.value === prediction)?.title ?? "";
}

function inviteTokenFromPath() {
  const segment = window.location.pathname.split("/").filter(Boolean).at(-1);
  return segment && /^[A-Za-z0-9_-]{43}$/.test(segment) ? segment : null;
}

export function GuestVotePage() {
  const [state, dispatch] = useReducer(voteReducer, initialVoteState);

  async function openInvite() {
    const token = inviteTokenFromPath();
    if (!token) return dispatch({ type: "unavailable", retryable: false });
    try {
      const response = await fetch("/functions/v1/guest-invite", {
        method: "POST",
        credentials: "same-origin",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ inviteToken: token }),
      });
      const dilemma = response.ok ? parseDilemmaResponse(await response.json()) : null;
      dispatch(dilemma ? { type: "opened", dilemma } : { type: "unavailable" });
    } catch {
      dispatch({ type: "unavailable" });
    }
  }

  useEffect(() => { void openInvite(); }, []);

  async function submitVote() {
    if (state.status !== "voting" || !state.selected || state.sending) return;
    dispatch({ type: "sending" });
    try {
      const response = await fetch("/functions/v1/guest-invite/vote", {
        method: "POST",
        credentials: "same-origin",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ dilemmaId: state.dilemma.dilemmaId, prediction: state.selected }),
      });
      const vote = response.ok ? parseVoteResponse(await response.json()) : null;
      dispatch(vote ? { type: "submitted", ...vote } : { type: "unavailable" });
    } catch {
      dispatch({ type: "unavailable" });
    }
  }

  if (state.status === "opening") return <Opening />;
  if (state.status === "unavailable") return <Unavailable retry={state.retryable ? openInvite : undefined} />;
  if (state.status === "confirmed") {
    return <Confirmation prediction={state.prediction} onShowAggregates={() => dispatch({ type: "showAggregates" })} />;
  }
  if (state.status === "aggregates") {
    return <AggregatePage aggregates={state.aggregates} prediction={state.prediction} onChangeVote={() => dispatch({ type: "changeVote" })} />;
  }

  const { dilemma, selected, sending } = state;
  return <main className="bib-shell">
    <Brand />
    <h1>{dilemma.ownerDisplayName} quer sua perspectiva</h1>
    <p className="intro">Você foi convidado a opinar sobre uma decisão de compra.</p>
    <section className="summary" aria-label="Detalhes do dilema">
      <p className="eyebrow">O que está sendo considerado</p>
      <h2>{dilemma.itemName}</h2>
      <p className="price">{price(dilemma.priceCents)}</p>
      <dl><div><dt>Categoria</dt><dd>{dilemma.category}</dd></div><div><dt>Para quem</dt><dd>{dilemma.purpose === "gift" ? "Presente" : "Para si"}</dd></div></dl>
      <p className="reason">{dilemma.reason}</p>
    </section>
    <fieldset className="vote-options" disabled={sending}>
      <legend>O que essa pessoa provavelmente vai ficar feliz de ter feito?</legend>
      {options.map((option) => <label className={`vote-option ${selected === option.value ? "selected" : ""}`} key={option.value}>
        <input type="radio" name="prediction" value={option.value} checked={selected === option.value} onChange={() => dispatch({ type: "select", prediction: option.value })} />
        <span><strong>{option.title}</strong><small>{option.detail}</small></span>
        {selected === option.value && <em>Meu palpite</em>}
      </label>)}
    </fieldset>
    <p className="privacy">Seu palpite ajuda. A decisão final é de {dilemma.ownerDisplayName}.</p>
    {selected && <button className="primary" type="button" onClick={submitVote} disabled={sending}>{sending ? "Enviando…" : "Enviar meu palpite"}</button>}
  </main>;
}

function Brand() { return <p className="brand" aria-label="Before I Buy">◒ Before I Buy</p>; }

function Opening() { return <main className="bib-shell loading" aria-busy="true"><Brand /><p aria-live="polite">Abrindo convite…</p><div className="skeleton" /><div className="skeleton" /><div className="skeleton" /></main>; }

function Unavailable({ retry }: { retry?: () => void }) { return <main className="bib-shell unavailable"><Brand /><h1>Este convite não está disponível</h1><p aria-live="assertive">Não foi possível abrir este convite. Tente novamente ou peça um novo link.</p>{retry && <button className="primary" type="button" onClick={retry}>Tentar novamente</button>}</main>; }

function Confirmation({ prediction, onShowAggregates }: { prediction: Prediction; onShowAggregates: () => void }) { return <main className="bib-shell confirmation"><Brand /><p className="success-icon" aria-hidden="true">✓</p><h1>Seu palpite entrou</h1><p>Você escolheu <strong>{predictionLabel(prediction)}</strong>. Obrigado por ajudar a pensar com um pouco mais de espaço.</p><button className="primary" type="button" onClick={onShowAggregates}>Ver como o grupo respondeu</button></main>; }

function AggregatePage({ aggregates, prediction, onChangeVote }: { aggregates: Aggregates; prediction: Prediction; onChangeVote: () => void }) { return <main className="bib-shell"><Brand /><h1>Perspectivas do grupo</h1><p>Seu palpite: <strong>{predictionLabel(prediction)}</strong></p><div className="aggregates" aria-label={`${aggregates.total} palpites no total`}>{options.map((option) => <p key={option.value}><span>{option.title}</span><strong>{aggregates[option.value]}</strong></p>)}</div><button className="secondary" type="button" onClick={onChangeVote}>Mudar meu palpite</button><p className="privacy">As respostas são anônimas. A decisão continua sendo da pessoa que criou o dilema.</p></main>; }
