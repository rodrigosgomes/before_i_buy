const allowedPaths = new Set([
  "/functions/v1/guest-invite",
  "/functions/v1/guest-invite/vote",
]);

const forwardedHeaders = ["accept", "content-type", "cookie", "origin"];
const protectedResponseHeaders = [
  "cache-control",
  "content-type",
  "referrer-policy",
  "x-robots-tag",
];

function unavailableResponse(status = 404) {
  return new Response(JSON.stringify({ error: "invite_unavailable" }), {
    status,
    headers: {
      "Cache-Control": "no-store",
      "Content-Type": "application/json; charset=utf-8",
      "Referrer-Policy": "no-referrer",
      "X-Robots-Tag": "noindex, nofollow",
    },
  });
}

function readEdgeOrigin(edgeOrigin = process.env.GUEST_INVITE_EDGE_ORIGIN) {
  if (!edgeOrigin) return null;
  try {
    const url = new URL(edgeOrigin);
    return url.origin === edgeOrigin ? url : null;
  } catch {
    return null;
  }
}

function setCookieValues(headers: Headers): string[] {
  const getSetCookie = headers.getSetCookie;
  if (typeof getSetCookie === "function") return getSetCookie.call(headers);
  const value = headers.get("set-cookie");
  return value ? [value] : [];
}

export async function proxyGuestInvite(
  request: Request,
  path: string,
  { edgeOrigin, fetcher = fetch }: { edgeOrigin?: string; fetcher?: typeof fetch } = {},
) {
  if (request.method !== "POST" || !allowedPaths.has(path)) {
    return unavailableResponse();
  }
  const upstreamOrigin = readEdgeOrigin(edgeOrigin);
  if (!upstreamOrigin) return unavailableResponse();

  const headers = new Headers();
  for (const name of forwardedHeaders) {
    const value = request.headers.get(name);
    if (value) headers.set(name, value);
  }

  try {
    const upstream = await fetcher(new URL(path, upstreamOrigin), {
      method: "POST",
      headers,
      body: await request.arrayBuffer(),
      redirect: "manual",
    });
    const responseHeaders = new Headers();
    for (const name of protectedResponseHeaders) {
      const value = upstream.headers.get(name);
      if (value) responseHeaders.set(name, value);
    }
    for (const cookie of setCookieValues(upstream.headers)) {
      responseHeaders.append("Set-Cookie", cookie);
    }
    return new Response(upstream.body, {
      status: upstream.status,
      headers: responseHeaders,
    });
  } catch {
    return unavailableResponse();
  }
}
