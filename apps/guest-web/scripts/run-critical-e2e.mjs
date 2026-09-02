import { createServer } from "node:http";
import { spawn } from "node:child_process";

const token = "A".repeat(43);
const cookie = "before_i_buy_guest_session=opaque-session";
let hasCookie = false;

function json(response, status, body, headers = {}) {
  response.writeHead(status, { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store", "Referrer-Policy": "no-referrer", "X-Robots-Tag": "noindex, nofollow", ...headers });
  response.end(JSON.stringify(body));
}

const upstream = createServer((request, response) => {
  if (request.headers.origin !== "http://localhost:3100") return json(response, 404, { error: "invite_unavailable" });
  if (request.url === "/functions/v1/guest-invite" && request.method === "POST") {
    let body = "";
    request.on("data", (chunk) => { body += chunk; });
    request.on("end", () => {
      if (JSON.parse(body).inviteToken !== token) return json(response, 404, { error: "invite_unavailable" });
      json(response, 200, { dilemma: { dilemma_id: "11111111-1111-4111-8111-111111111111", owner_display_name: "Lu", item_name: "Fone com cancelamento de ruído", price_cents: 240000, currency: "BRL", category: "Tecnologia", purpose: "self", reason: "Quero mais foco para trabalhar.", pause_due_at: "2026-09-04T00:00:00.000Z" } }, { "Set-Cookie": `${cookie}; Path=/functions/v1/guest-invite; HttpOnly; Secure; SameSite=Strict` });
    });
    return;
  }
  if (request.url === "/functions/v1/guest-invite/vote" && request.method === "POST") {
    hasCookie = request.headers.cookie?.includes(cookie) ?? false;
    let body = "";
    request.on("data", (chunk) => { body += chunk; });
    request.on("end", () => {
      const prediction = JSON.parse(body).prediction;
      if (hasCookie) {
        json(response, 200, { vote: { prediction, changed: prediction !== "wait" }, aggregates: { buy: prediction === "buy" ? 2 : 1, wait: prediction === "wait" ? 2 : 1, skip: 0, total: 3 } });
      } else {
        json(response, 404, { error: "vote_unavailable" });
      }
    });
    return;
  }
  return json(response, 404, { error: "invite_unavailable" });
});

function waitForServer(process) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error("Next.js did not start.")), 20_000);
    process.stdout.on("data", (data) => { if (String(data).includes("Ready")) { clearTimeout(timer); resolve(); } });
    process.stderr.on("data", (data) => { if (String(data).includes("Ready")) { clearTimeout(timer); resolve(); } });
    process.on("exit", (code) => { if (code) reject(new Error(`Next.js exited with ${code}.`)); });
  });
}

await new Promise((resolve) => upstream.listen(4111, "127.0.0.1", resolve));
const next = spawn("./node_modules/.bin/next", ["dev", "--hostname", "localhost", "--port", "3100"], { env: { ...process.env, GUEST_INVITE_EDGE_ORIGIN: "http://127.0.0.1:4111" }, stdio: ["ignore", "pipe", "pipe"] });
try {
  await waitForServer(next);
  const playwright = spawn("./node_modules/.bin/playwright", ["test"], { stdio: "inherit" });
  const exitCode = await new Promise((resolve) => playwright.on("exit", (code) => resolve(code ?? 1)));
  if (exitCode !== 0 || !hasCookie) process.exitCode = 1;
} finally {
  next.kill("SIGTERM");
  await new Promise((resolve) => upstream.close(resolve));
}
