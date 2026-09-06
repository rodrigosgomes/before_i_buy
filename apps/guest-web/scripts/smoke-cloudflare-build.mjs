import assert from "node:assert/strict";
import { spawn } from "node:child_process";

const token = "A".repeat(43);
const port = "3201";
const wrangler = spawn(
  "./node_modules/.bin/wrangler",
  ["dev", "--local", "--port", port],
  { stdio: ["ignore", "pipe", "pipe"] },
);

function waitUntilReady() {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error("Cloudflare preview did not start.")), 20_000);
    const inspect = (chunk) => {
      if (String(chunk).includes("Ready on")) {
        clearTimeout(timeout);
        resolve();
      }
    };
    wrangler.stdout.on("data", inspect);
    wrangler.stderr.on("data", inspect);
    wrangler.on("exit", (code) => reject(new Error(`Cloudflare preview exited with ${code}.`)));
  });
}

try {
  await waitUntilReady();
  const response = await fetch(
    `http://localhost:${port}/eloease/guest-invite/invite/${token}`,
  );
  const html = await response.text();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("cache-control") ?? "", /no-store/);
  assert.equal(response.headers.get("referrer-policy"), "no-referrer");
  assert.match(response.headers.get("x-robots-tag") ?? "", /noindex/);
  assert.equal(html.includes(token), false, "invite token must not enter SSR HTML");
  assert.match(html, /Before I Buy/);
} finally {
  wrangler.kill("SIGTERM");
}
