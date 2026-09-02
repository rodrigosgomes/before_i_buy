import React from "react";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";

import { GuestVotePage } from "../src/components/guest-vote-page";

const token = "A".repeat(43);
const invite = { dilemma: { dilemma_id: "11111111-1111-4111-8111-111111111111", owner_display_name: "Lu", item_name: "Fone", price_cents: 240000, currency: "BRL", category: "Tecnologia", purpose: "self", reason: "Quero mais foco.", pause_due_at: "2026-09-04T00:00:00.000Z" } };

describe("GuestVotePage", () => {
  beforeEach(() => {
    window.history.pushState({}, "", `/invite/${token}`);
  });

  afterEach(() => vi.unstubAllGlobals());

  it("does not show aggregates until the vote has succeeded and the guest asks to see them", async () => {
    const fetch = vi.fn()
      .mockResolvedValueOnce(new Response(JSON.stringify(invite), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ vote: { prediction: "wait" }, aggregates: { buy: 1, wait: 2, skip: 0, total: 3 } }), { status: 200 }));
    vi.stubGlobal("fetch", fetch);
    render(<GuestVotePage />);
    expect(screen.getByText("Abrindo convite…")).toBeTruthy();
    await screen.findByRole("heading", { name: "Lu quer sua perspectiva" });
    expect(screen.queryByText("Perspectivas do grupo")).toBeNull();
    fireEvent.click(screen.getByLabelText(/Esperar/));
    fireEvent.click(screen.getByRole("button", { name: "Enviar meu palpite" }));
    await screen.findByRole("heading", { name: "Seu palpite entrou" });
    expect(screen.queryByText("Perspectivas do grupo")).toBeNull();
    fireEvent.click(screen.getByRole("button", { name: "Ver como o grupo respondeu" }));
    expect(await screen.findByRole("heading", { name: "Perspectivas do grupo" })).toBeTruthy();
    fireEvent.click(screen.getByRole("button", { name: "Mudar meu palpite" }));
    expect(await screen.findByRole("button", { name: "Enviar meu palpite" })).toBeTruthy();
    expect(fetch.mock.calls[1][0]).toBe("/functions/v1/guest-invite/vote");
  });

  it("shows the generic unavailable state without rendering private data", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(new Response(JSON.stringify({ error: "invite_unavailable" }), { status: 404 })));
    render(<GuestVotePage />);
    expect(await screen.findByRole("heading", { name: "Este convite não está disponível" })).toBeTruthy();
    expect(screen.queryByText("Fone")).toBeNull();
  });

  it("keeps a selected prediction after a recoverable vote failure", async () => {
    vi.stubGlobal("fetch", vi.fn()
      .mockResolvedValueOnce(new Response(JSON.stringify(invite), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ error: "vote_unavailable" }), { status: 404 })));
    render(<GuestVotePage />);
    await screen.findByRole("heading", { name: "Lu quer sua perspectiva" });
    const choice = screen.getByLabelText(/Comprar/);
    fireEvent.click(choice);
    fireEvent.click(screen.getByRole("button", { name: "Enviar meu palpite" }));
    await waitFor(() => expect(choice).toHaveProperty("checked", true));
    expect(screen.getByRole("button", { name: "Enviar meu palpite" })).toBeTruthy();
  });
});
