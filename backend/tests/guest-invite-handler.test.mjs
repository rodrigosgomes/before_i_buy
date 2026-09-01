import assert from "node:assert/strict";
import test from "node:test";

import {
  createGuestSessionSecret,
  createRateLimitKey,
  handleGuestInvite,
  handleGuestInviteRequest,
  handleGuestVote,
} from "../supabase/functions/guest-invite/handler.mjs";

const validInviteToken = "I".repeat(43);
const invalidInviteToken = "J".repeat(43);
const failedInviteToken = "K".repeat(43);
const rateLimitKey = "a".repeat(64);
const allowedOrigin = "https://guest.example.test";
const deriveRateLimitKey = async () => rateLimitKey;

const validProjection = {
  rate_limited: false,
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

const validVoteProjection = {
  rate_limited: false,
  prediction: "buy",
  changed: false,
  buy_count: 2,
  wait_count: 1,
  skip_count: 0,
  total_votes: 3,
  participation_id: "must-not-leak",
  guest_session_id: "must-not-leak",
  session_secret_hash: "must-not-leak",
};

test("generates a 256-bit Base64URL guest-session secret", () => {
  const secret = createGuestSessionSecret();

  assert.match(secret, /^[A-Za-z0-9_-]{43}$/);
});

test("derives opaque and scope-separated HMAC rate-limit keys", async () => {
  const secret = "rate-limit-secret-with-at-least-32-bytes";
  const inviteKey = await createRateLimitKey("invite_open", validInviteToken, secret);
  const voteKey = await createRateLimitKey("guest_vote", validInviteToken, secret);

  assert.match(inviteKey, /^[0-9a-f]{64}$/);
  assert.match(voteKey, /^[0-9a-f]{64}$/);
  assert.notEqual(inviteKey, voteKey);
  await assert.rejects(
    () => createRateLimitKey("invite_open", validInviteToken, "too-short"),
    /at least 32 bytes/,
  );
});

test("opens a guest session through the private RPC and returns only the guest projection", async () => {
  const calls = [];
  const response = await handleGuestInvite(
    new Request("https://example.test/functions/v1/guest-invite", {
      method: "POST",
      body: JSON.stringify({ inviteToken: validInviteToken }),
    }),
    {
      openGuestInviteSession: async (inviteToken, sessionSecret, derivedKey) => {
        calls.push({ inviteToken, sessionSecret, derivedKey });
        return validProjection;
      },
      createSessionSecret: () => "A".repeat(43),
      deriveRateLimitKey,
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
    inviteToken: validInviteToken,
    sessionSecret: "A".repeat(43),
    derivedKey: rateLimitKey,
  }]);
  assert.match(response.headers.get("set-cookie"), /before_i_buy_guest_session=A{43}/);
  assert.match(response.headers.get("set-cookie"), /HttpOnly/);
  assert.match(response.headers.get("set-cookie"), /Secure/);
  assert.match(response.headers.get("set-cookie"), /SameSite=Strict/);
  assert.match(
    response.headers.get("set-cookie"),
    /Path=\/functions\/v1\/guest-invite/,
  );
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
    { openGuestInviteSession: async () => validProjection, deriveRateLimitKey, now },
  );
  const invalid = await handleGuestInvite(
    new Request("https://example.test/functions/v1/guest-invite", {
      method: "POST",
      body: JSON.stringify({ inviteToken: invalidInviteToken }),
    }),
    { openGuestInviteSession: async () => null, deriveRateLimitKey, now },
  );
  const failed = await handleGuestInvite(
    new Request("https://example.test/functions/v1/guest-invite", {
      method: "POST",
      body: JSON.stringify({ inviteToken: failedInviteToken }),
    }),
    {
      openGuestInviteSession: async () => { throw new Error("database failure"); },
      deriveRateLimitKey,
      now,
    },
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

test("returns a generic 429 without a cookie when invite opening is limited", async () => {
  const response = await handleGuestInvite(
    new Request("https://example.test/functions/v1/guest-invite", {
      method: "POST",
      body: JSON.stringify({ inviteToken: validInviteToken }),
    }),
    {
      openGuestInviteSession: async () => ({ rate_limited: true }),
      deriveRateLimitKey,
      createSessionSecret: () => "A".repeat(43),
      now,
    },
  );

  assert.equal(response.status, 429);
  assert.deepEqual(await response.json(), { error: "invite_unavailable" });
  assert.equal(response.headers.get("set-cookie"), null);
  assert.equal(response.headers.get("cache-control"), "no-store");
});

test("submits a scoped guest vote from the HttpOnly session cookie", async () => {
  const calls = [];
  const response = await handleGuestVote(
    new Request("https://example.test/functions/v1/guest-invite/vote", {
      method: "POST",
      headers: {
        cookie: `unrelated=value; before_i_buy_guest_session=${"B".repeat(43)}; another=value`,
      },
      body: JSON.stringify({
        dilemmaId: "10000000-0000-4000-8000-000000000001",
        prediction: "buy",
      }),
    }),
    {
      submitGuestVote: async (dilemmaId, sessionSecret, prediction, derivedKey) => {
        calls.push({ dilemmaId, sessionSecret, prediction, derivedKey });
        return validVoteProjection;
      },
      deriveRateLimitKey,
    },
  );

  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), {
    vote: {
      prediction: "buy",
      changed: false,
    },
    aggregates: {
      buy: 2,
      wait: 1,
      skip: 0,
      total: 3,
    },
  });
  assert.deepEqual(calls, [{
    dilemmaId: "10000000-0000-4000-8000-000000000001",
    sessionSecret: "B".repeat(43),
    prediction: "buy",
    derivedKey: rateLimitKey,
  }]);
  assert.equal(response.headers.get("set-cookie"), null);
  assert.equal(response.headers.get("cache-control"), "no-store");
  assert.equal(response.headers.get("referrer-policy"), "no-referrer");
  assert.equal(response.headers.get("x-robots-tag"), "noindex, nofollow");
});

test("accepts buy, wait, and skip through the HTTP contract", async () => {
  for (const prediction of ["buy", "wait", "skip"]) {
    const response = await handleGuestVote(
      new Request("https://example.test/functions/v1/guest-invite/vote", {
        method: "POST",
        headers: {
          cookie: `before_i_buy_guest_session=${"P".repeat(43)}`,
        },
        body: JSON.stringify({
          dilemmaId: "10000000-0000-4000-8000-000000000001",
          prediction,
        }),
      }),
      {
        submitGuestVote: async () => ({
          ...validVoteProjection,
          prediction,
          buy_count: prediction === "buy" ? 1 : 0,
          wait_count: prediction === "wait" ? 1 : 0,
          skip_count: prediction === "skip" ? 1 : 0,
          total_votes: 1,
        }),
        deriveRateLimitKey,
      },
    );

    assert.equal(response.status, 200);
    assert.equal((await response.json()).vote.prediction, prediction);
  }
});

test("returns one generic vote failure without calling the RPC for malformed input", async () => {
  let calls = 0;
  const submitGuestVote = async () => {
    calls += 1;
    return validVoteProjection;
  };
  const requests = [
    new Request("https://example.test/functions/v1/guest-invite/vote", {
      method: "GET",
      headers: { cookie: `before_i_buy_guest_session=${"B".repeat(43)}` },
    }),
    new Request("https://example.test/functions/v1/guest-invite/vote", {
      method: "POST",
      body: JSON.stringify({
        dilemmaId: "10000000-0000-4000-8000-000000000001",
        prediction: "buy",
      }),
    }),
    new Request("https://example.test/functions/v1/guest-invite/vote", {
      method: "POST",
      headers: { cookie: "before_i_buy_guest_session=too-short" },
      body: JSON.stringify({
        dilemmaId: "10000000-0000-4000-8000-000000000001",
        prediction: "buy",
      }),
    }),
    new Request("https://example.test/functions/v1/guest-invite/vote", {
      method: "POST",
      headers: { cookie: `before_i_buy_guest_session=${"B".repeat(43)}` },
      body: "not-json",
    }),
    new Request("https://example.test/functions/v1/guest-invite/vote", {
      method: "POST",
      headers: { cookie: `before_i_buy_guest_session=${"B".repeat(43)}` },
      body: JSON.stringify({ dilemmaId: "not-a-uuid", prediction: "buy" }),
    }),
    new Request("https://example.test/functions/v1/guest-invite/vote", {
      method: "POST",
      headers: { cookie: `before_i_buy_guest_session=${"B".repeat(43)}` },
      body: JSON.stringify({
        dilemmaId: "10000000-0000-4000-8000-000000000001",
        prediction: "maybe",
      }),
    }),
  ];

  for (const request of requests) {
    const response = await handleGuestVote(request, {
      submitGuestVote,
      deriveRateLimitKey,
    });
    assert.equal(response.status, 404);
    assert.deepEqual(await response.json(), { error: "vote_unavailable" });
    assert.equal(response.headers.get("set-cookie"), null);
  }
  assert.equal(calls, 0);
});

test("returns the same generic response for denied, failed, or malformed vote projections", async () => {
  const request = () => new Request(
    "https://example.test/functions/v1/guest-invite/vote",
    {
      method: "POST",
      headers: { cookie: `before_i_buy_guest_session=${"C".repeat(43)}` },
      body: JSON.stringify({
        dilemmaId: "10000000-0000-4000-8000-000000000001",
        prediction: "skip",
      }),
    },
  );
  const malformedProjections = [
    null,
    { ...validVoteProjection, total_votes: 99 },
    { ...validVoteProjection, buy_count: -1 },
    { ...validVoteProjection, changed: "false" },
    { ...validVoteProjection, prediction: "invalid" },
  ];

  for (const projection of malformedProjections) {
    const response = await handleGuestVote(request(), {
      submitGuestVote: async () => projection,
      deriveRateLimitKey,
    });
    assert.equal(response.status, 404);
    assert.deepEqual(await response.json(), { error: "vote_unavailable" });
  }

  const failed = await handleGuestVote(request(), {
    submitGuestVote: async () => { throw new Error("database failure"); },
    deriveRateLimitKey,
  });
  assert.equal(failed.status, 404);
  assert.deepEqual(await failed.json(), { error: "vote_unavailable" });
});

test("returns a generic 429 when the guest session vote limit is reached", async () => {
  const response = await handleGuestVote(
    new Request("https://example.test/functions/v1/guest-invite/vote", {
      method: "POST",
      headers: { cookie: `before_i_buy_guest_session=${"C".repeat(43)}` },
      body: JSON.stringify({
        dilemmaId: "10000000-0000-4000-8000-000000000001",
        prediction: "wait",
      }),
    }),
    {
      submitGuestVote: async () => ({ rate_limited: true }),
      deriveRateLimitKey,
    },
  );

  assert.equal(response.status, 429);
  assert.deepEqual(await response.json(), { error: "vote_unavailable" });
  assert.equal(response.headers.get("cache-control"), "no-store");
});

test("routes only the exact guest-invite paths", async () => {
  const routedVote = await handleGuestInviteRequest(
    new Request("https://example.test/functions/v1/guest-invite/vote/", {
      method: "POST",
      headers: { cookie: `before_i_buy_guest_session=${"D".repeat(43)}` },
      body: JSON.stringify({
        dilemmaId: "10000000-0000-4000-8000-000000000001",
        prediction: "buy",
      }),
    }),
    {
      submitGuestVote: async () => validVoteProjection,
      deriveRateLimitKey,
    },
  );
  assert.equal(routedVote.status, 200);

  const internalOpen = await handleGuestInviteRequest(
    new Request("http://guest-invite/guest-invite", {
      method: "POST",
      body: JSON.stringify({ inviteToken: validInviteToken }),
    }),
    {
      openGuestInviteSession: async () => validProjection,
      deriveRateLimitKey,
      createSessionSecret: () => "E".repeat(43),
      now,
    },
  );
  assert.equal(internalOpen.status, 200);

  const internalVote = await handleGuestInviteRequest(
    new Request("http://guest-invite/guest-invite/vote", {
      method: "POST",
      headers: { cookie: `before_i_buy_guest_session=${"E".repeat(43)}` },
      body: JSON.stringify({
        dilemmaId: "10000000-0000-4000-8000-000000000001",
        prediction: "buy",
      }),
    }),
    {
      submitGuestVote: async () => validVoteProjection,
      deriveRateLimitKey,
    },
  );
  assert.equal(internalVote.status, 200);

  const unknown = await handleGuestInviteRequest(
    new Request("https://example.test/not-the-function/guest-invite", {
      method: "POST",
      body: JSON.stringify({ inviteToken: validInviteToken }),
    }),
    { openGuestInviteSession: async () => validProjection },
  );
  assert.equal(unknown.status, 404);
  assert.deepEqual(await unknown.json(), { error: "invite_unavailable" });
});

test("accepts only the configured browser origin through the same-origin proxy", async () => {
  let rejectedCalls = 0;
  const rejected = await handleGuestInviteRequest(
    new Request("https://api.example.test/functions/v1/guest-invite", {
      method: "POST",
      headers: {
        origin: "https://attacker.example.test",
        "content-type": "application/json",
      },
      body: JSON.stringify({ inviteToken: validInviteToken }),
    }),
    {
      allowedOrigin,
      openGuestInviteSession: async () => {
        rejectedCalls += 1;
        return validProjection;
      },
      deriveRateLimitKey,
    },
  );

  assert.equal(rejected.status, 404);
  assert.equal(rejected.headers.get("access-control-allow-origin"), null);
  assert.equal(rejectedCalls, 0);

  const accepted = await handleGuestInviteRequest(
    new Request("https://api.example.test/functions/v1/guest-invite", {
      method: "POST",
      headers: {
        origin: allowedOrigin,
        "content-type": "application/json",
      },
      body: JSON.stringify({ inviteToken: validInviteToken }),
    }),
    {
      allowedOrigin,
      openGuestInviteSession: async () => validProjection,
      createSessionSecret: () => "N".repeat(43),
      deriveRateLimitKey,
      now,
    },
  );

  assert.equal(accepted.status, 200);
  assert.equal(accepted.headers.get("access-control-allow-origin"), null);
});
