const privacyHeaders = {
  "Cache-Control": "no-store",
  "Content-Type": "application/json; charset=utf-8",
  "Referrer-Policy": "no-referrer",
  "X-Robots-Tag": "noindex, nofollow",
};

const guestSessionCookieName = "before_i_buy_guest_session";
const votePredictions = new Set(["buy", "wait", "skip"]);

function responseHeaders() {
  return new Headers(privacyHeaders);
}

function isAllowedOrigin(request, allowedOrigin) {
  const origin = request.headers.get("origin");
  return origin === null || origin === allowedOrigin;
}

function unavailableInviteResponse(
  status = 404,
  request,
  allowedOrigin,
) {
  return new Response(JSON.stringify({ error: "invite_unavailable" }), {
    status,
    headers: responseHeaders(request, allowedOrigin),
  });
}

function unavailableVoteResponse(status = 404, request, allowedOrigin) {
  return new Response(JSON.stringify({ error: "vote_unavailable" }), {
    status,
    headers: responseHeaders(request, allowedOrigin),
  });
}

function base64Url(bytes) {
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }

  return btoa(binary)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

export function createGuestSessionSecret() {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return base64Url(bytes);
}

export async function createRateLimitKey(scope, subject, secret) {
  const encoder = new TextEncoder();
  const secretBytes = encoder.encode(secret);
  if (secretBytes.length < 32) {
    throw new Error("Rate-limit secret must contain at least 32 bytes.");
  }

  const key = await crypto.subtle.importKey(
    "raw",
    secretBytes,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const digest = new Uint8Array(await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(`${scope}\u0000${subject}`),
  ));
  return [...digest]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function serializeSessionCookie(secret, maxAge) {
  return [
    `before_i_buy_guest_session=${secret}`,
    "Path=/functions/v1/guest-invite",
    "HttpOnly",
    "Secure",
    "SameSite=Strict",
    `Max-Age=${maxAge}`,
  ].join("; ");
}

function isPlausibleInviteToken(value) {
  return typeof value === "string" && /^[A-Za-z0-9_-]{43}$/.test(value);
}

function isUuid(value) {
  return typeof value === "string" &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
      .test(value);
}

function readGuestSessionSecret(request) {
  const cookieHeader = request.headers.get("cookie");
  if (!cookieHeader) return null;

  for (const entry of cookieHeader.split(";")) {
    const separator = entry.indexOf("=");
    if (separator < 0) continue;
    const name = entry.slice(0, separator).trim();
    if (name !== guestSessionCookieName) continue;
    const value = entry.slice(separator + 1).trim();
    return /^[A-Za-z0-9_-]{43}$/.test(value) ? value : null;
  }

  return null;
}

function isValidVoteProjection(projection) {
  if (!projection || typeof projection !== "object") return false;
  if (!votePredictions.has(projection.prediction)) return false;
  if (typeof projection.changed !== "boolean") return false;

  const counts = [
    projection.buy_count,
    projection.wait_count,
    projection.skip_count,
    projection.total_votes,
  ];
  if (!counts.every((count) => Number.isSafeInteger(count) && count >= 0)) {
    return false;
  }

  return projection.buy_count + projection.wait_count + projection.skip_count ===
    projection.total_votes;
}

const maximumBodyBytes = 2048;

export async function readLimitedJson(request) {
  const contentType = request.headers.get("content-type");
  if (contentType && !contentType.toLowerCase().startsWith("application/json")) {
    return null;
  }
  const declaredLength = Number(request.headers.get("content-length"));
  if (Number.isFinite(declaredLength) && declaredLength > maximumBodyBytes) return null;
  if (!request.body) return null;
  const reader = request.body.getReader();
  const chunks = [];
  let total = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    total += value.byteLength;
    if (total > maximumBodyBytes) {
      await reader.cancel();
      return null;
    }
    chunks.push(value.slice());
  }
  const body = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    body.set(chunk, offset);
    offset += chunk.byteLength;
  }
  try {
    return JSON.parse(new TextDecoder().decode(body));
  } catch {
    return null;
  }
}

export async function handleGuestInvite(
  request,
  {
    openGuestInviteSession,
    createSessionSecret = createGuestSessionSecret,
    deriveRateLimitKey,
    allowedOrigin,
    now = () => new Date(),
  },
) {
  if (!isAllowedOrigin(request, allowedOrigin)) {
    return unavailableInviteResponse(404, request, allowedOrigin);
  }

  if (request.method !== "POST") {
    return unavailableInviteResponse(404, request, allowedOrigin);
  }

  const payload = await readLimitedJson(request);

  if (!isPlausibleInviteToken(payload?.inviteToken)) {
    return unavailableInviteResponse(404, request, allowedOrigin);
  }

  const sessionSecret = createSessionSecret();
  let rateLimitKey;
  try {
    rateLimitKey = await deriveRateLimitKey("invite_open", payload.inviteToken);
  } catch {
    return unavailableInviteResponse(404, request, allowedOrigin);
  }

  let projection;
  try {
    projection = await openGuestInviteSession(
      payload.inviteToken,
      sessionSecret,
      rateLimitKey,
    );
  } catch {
    return unavailableInviteResponse(404, request, allowedOrigin);
  }

  if (!projection || typeof projection !== "object") {
    return unavailableInviteResponse(404, request, allowedOrigin);
  }
  if (projection.rate_limited === true) {
    return unavailableInviteResponse(429, request, allowedOrigin);
  }
  if (projection.rate_limited !== false) {
    return unavailableInviteResponse(404, request, allowedOrigin);
  }

  const expiresAt = new Date(projection.expires_at);
  const maxAge = Math.floor((expiresAt.getTime() - now().getTime()) / 1000);
  if (!Number.isFinite(expiresAt.getTime()) || maxAge <= 0) {
    return unavailableInviteResponse(404, request, allowedOrigin);
  }

  const dilemma = {
    dilemma_id: projection.dilemma_id,
    owner_display_name: projection.owner_display_name,
    item_name: projection.item_name,
    price_cents: projection.price_cents,
    currency: projection.currency,
    category: projection.category,
    purpose: projection.purpose,
    reason: projection.reason,
    pause_due_at: projection.pause_due_at,
    state: projection.state,
  };
  const headers = responseHeaders(request, allowedOrigin);
  headers.set("Set-Cookie", serializeSessionCookie(sessionSecret, maxAge));

  return new Response(JSON.stringify({ dilemma }), {
    status: 200,
    headers,
  });
}

export async function handleGuestVote(
  request,
  { submitGuestVote, deriveRateLimitKey, allowedOrigin },
) {
  if (!isAllowedOrigin(request, allowedOrigin)) {
    return unavailableVoteResponse(404, request, allowedOrigin);
  }

  if (request.method !== "POST") {
    return unavailableVoteResponse(404, request, allowedOrigin);
  }

  const sessionSecret = readGuestSessionSecret(request);
  if (!sessionSecret) {
    return unavailableVoteResponse(404, request, allowedOrigin);
  }

  const payload = await readLimitedJson(request);

  if (!isUuid(payload?.dilemmaId) || !votePredictions.has(payload?.prediction)) {
    return unavailableVoteResponse(404, request, allowedOrigin);
  }

  let rateLimitKey;
  try {
    rateLimitKey = await deriveRateLimitKey("guest_vote", sessionSecret);
  } catch {
    return unavailableVoteResponse(404, request, allowedOrigin);
  }

  let projection;
  try {
    projection = await submitGuestVote(
      payload.dilemmaId,
      sessionSecret,
      payload.prediction,
      rateLimitKey,
    );
  } catch {
    return unavailableVoteResponse(404, request, allowedOrigin);
  }

  if (projection?.rate_limited === true) {
    return unavailableVoteResponse(429, request, allowedOrigin);
  }

  if (
    projection?.rate_limited !== false ||
    !isValidVoteProjection(projection) ||
    projection.prediction !== payload.prediction
  ) {
    return unavailableVoteResponse(404, request, allowedOrigin);
  }

  return new Response(JSON.stringify({
    vote: {
      prediction: projection.prediction,
      changed: projection.changed,
    },
    aggregates: {
      buy: projection.buy_count,
      wait: projection.wait_count,
      skip: projection.skip_count,
      total: projection.total_votes,
    },
  }), {
    status: 200,
    headers: responseHeaders(request, allowedOrigin),
  });
}

export function handleGuestInviteRequest(request, dependencies) {
  const pathname = new URL(request.url).pathname.replace(/\/+$/, "");
  const isVotePath =
    pathname === "/functions/v1/guest-invite/vote" ||
    pathname === "/guest-invite/vote";
  const isOpenPath =
    pathname === "/functions/v1/guest-invite" ||
    pathname === "/guest-invite";

  if (isVotePath) {
    return handleGuestVote(request, dependencies);
  }
  if (isOpenPath) {
    return handleGuestInvite(request, dependencies);
  }
  return unavailableInviteResponse(404, request, dependencies.allowedOrigin);
}
