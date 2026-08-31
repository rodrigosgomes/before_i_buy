const privacyHeaders = {
  "Cache-Control": "no-store",
  "Content-Type": "application/json; charset=utf-8",
  "Referrer-Policy": "no-referrer",
  "X-Robots-Tag": "noindex, nofollow",
};

function unavailableInviteResponse() {
  return new Response(JSON.stringify({ error: "invite_unavailable" }), {
    status: 404,
    headers: privacyHeaders,
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
  return typeof value === "string" && value.length >= 16 && value.length <= 512;
}

export async function handleGuestInvite(
  request,
  {
    openGuestInviteSession,
    createSessionSecret = createGuestSessionSecret,
    now = () => new Date(),
  },
) {
  if (request.method !== "POST") {
    return unavailableInviteResponse();
  }

  let payload;
  try {
    payload = await request.json();
  } catch {
    return unavailableInviteResponse();
  }

  if (!isPlausibleInviteToken(payload?.inviteToken)) {
    return unavailableInviteResponse();
  }

  const sessionSecret = createSessionSecret();
  let projection;
  try {
    projection = await openGuestInviteSession(payload.inviteToken, sessionSecret);
  } catch {
    return unavailableInviteResponse();
  }

  if (!projection || typeof projection !== "object") {
    return unavailableInviteResponse();
  }

  const expiresAt = new Date(projection.expires_at);
  const maxAge = Math.floor((expiresAt.getTime() - now().getTime()) / 1000);
  if (!Number.isFinite(expiresAt.getTime()) || maxAge <= 0) {
    return unavailableInviteResponse();
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
  const headers = new Headers(privacyHeaders);
  headers.set("Set-Cookie", serializeSessionCookie(sessionSecret, maxAge));

  return new Response(JSON.stringify({ dilemma }), {
    status: 200,
    headers,
  });
}
