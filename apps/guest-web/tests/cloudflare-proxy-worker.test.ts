import worker from "../cloudflare-proxy/worker";

describe("Cloudflare root API worker", () => {
  it("routes the exact root endpoint without changing its path or origin", async () => {
    const originalFetch = globalThis.fetch;
    const fetcher = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
      expect(String(input)).toBe("https://edge.example/functions/v1/guest-invite");
      expect(new Headers(init?.headers).get("origin")).toBe("https://myelolabs.com.br");
      return new Response("{}", { status: 200, headers: { "Cache-Control": "no-store" } });
    });
    globalThis.fetch = fetcher as typeof fetch;
    try {
      const response = await worker.fetch(
        new Request("https://myelolabs.com.br/functions/v1/guest-invite", {
          method: "POST",
          headers: {
            Origin: "https://myelolabs.com.br",
            "Content-Type": "application/json",
          },
          body: "{}",
        }),
        { GUEST_INVITE_EDGE_ORIGIN: "https://edge.example" },
      );
      expect(response.status).toBe(200);
      expect(fetcher).toHaveBeenCalledOnce();
    } finally {
      globalThis.fetch = originalFetch;
    }
  });

  it("fails closed outside the two root API routes", async () => {
    const response = await worker.fetch(
      new Request("https://myelolabs.com.br/eloease/guest-invite", {
        method: "POST",
      }),
      { GUEST_INVITE_EDGE_ORIGIN: "https://edge.example" },
    );
    expect(response.status).toBe(404);
    expect(await response.json()).toEqual({ error: "invite_unavailable" });
  });
});
