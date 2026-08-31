import assert from "node:assert/strict";
import test from "node:test";

import {
  createGuestSessionSecret,
  handleGuestInvite,
} from "../supabase/functions/guest-invite/handler.mjs";

const validProjection = {
  dilemma_id: "10000000-0000-4000-8000-000000000001",
  owner_display_name: "Owner A",
  item_name: "Camera A",
  price_cents: 150000,
  currency: "BRL",
  category: "tech_electronics",
  purpose: "for_self",
  reason: "Preciso de uma camera para viagens.",
  pause_due_at: "2026-09-01T12:00:00.000Z",
  state: "collecting_votes",
  expires_at: "2026-09-01T12:00:00.000Z",
  total_votes: 99,
  image_url: "https://example.test/image.jpg",
  product_url: "https://example.test/product",
  invite_token_hash: "must-not-leak",
  session_secret_hash: "must-not-leak",
};

const now = () => new Date("2026-09-01T11:00:00.000Z");

test("generates a 256-bit Base64URL guest-session secret", () => {
  const secret = createGuestSessionSecret();

  assert.match(secret, /^[A-Za-z0-9_-]{43}$/);
});

test("opens a guest session through the private RPC and returns only the guest projection", async () => {
  const calls = [];
  const response = await handleGuestInvite(
    new Request("https://example.test/functions/v1/guest-invite", {
      method: "POST",
      body: JSON.stringify({ inviteToken: "invite-token-alpha" }),
    }),
    {
      openGuestInviteSession: async (inviteToken, sessionSecret) => {
        calls.push({ inviteToken, sessionSecret });
        return validProjection;
      },
      createSessionSecret: () => "A".repeat(43),
      now,
    },
  );

  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), {
    dilemma: {
      dilemma_id: validProjection.dilemma_id,
      owner_display_name: validProjection.owner_display_name,
      item_name: validProjection.item_name,
      price_cents: validProjection.price_cents,
      currency: validProjection.currency,
      category: validProjection.category,
      purpose: validProjection.purpose,
      reason: validProjection.reason,
      pause_due_at: validProjection.pause_due_at,
      state: validProjection.state,
    },
  });
  assert.deepEqual(calls, [{
    inviteToken: "invite-token-alpha",
    sessionSecret: "A".repeat(43),
  }]);
  assert.match(response.headers.get("set-cookie"), /before_i_buy_guest_session=A{43}/);
  assert.match(response.headers.get("set-cookie"), /HttpOnly/);
  assert.match(response.headers.get("set-cookie"), /Secure/);
  assert.match(response.headers.get("set-cookie"), /SameSite=Strict/);
  assert.match(response.headers.get("set-cookie"), /Max-Age=3600/);
  assert.equal(response.headers.get("cache-control"), "no-store");
  assert.equal(response.headers.get("referrer-policy"), "no-referrer");
  assert.equal(response.headers.get("x-robots-tag"), "noindex, nofollow");
});

test("returns the same generic response for malformed, invalid, and failed invites", async () => {
  const malformed = await handleGuestInvite(
    new Request("https://example.test/functions/v1/guest-invite", {
      method: "POST",
      body: "not-json",
    }),
    { openGuestInviteSession: async () => validProjection, now },
  );
  const invalid = await handleGuestInvite(
    new Request("https://example.test/functions/v1/guest-invite", {
      method: "POST",
      body: JSON.stringify({ inviteToken: "invite-token-invalid" }),
    }),
    { openGuestInviteSession: async () => null, now },
  );
  const failed = await handleGuestInvite(
    new Request("https://example.test/functions/v1/guest-invite", {
      method: "POST",
      body: JSON.stringify({ inviteToken: "invite-token-failure" }),
    }),
    { openGuestInviteSession: async () => { throw new Error("database failure"); }, now },
  );

  const expectedBody = JSON.stringify({ error: "invite_unavailable" });
  for (const response of [malformed, invalid, failed]) {
    assert.equal(response.status, 404);
    assert.equal(await response.text(), expectedBody);
    assert.equal(response.headers.get("set-cookie"), null);
    assert.equal(response.headers.get("cache-control"), "no-store");
    assert.equal(response.headers.get("referrer-policy"), "no-referrer");
    assert.equal(response.headers.get("x-robots-tag"), "noindex, nofollow");
  }
});

test("does not issue a cookie for a non-POST request", async () => {
  const response = await handleGuestInvite(
    new Request("https://example.test/functions/v1/guest-invite"),
    { openGuestInviteSession: async () => validProjection, now },
  );

  assert.equal(response.status, 404);
  assert.equal(response.headers.get("set-cookie"), null);
});
