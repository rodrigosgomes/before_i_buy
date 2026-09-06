import { proxyGuestInvite } from "../src/lib/proxy";

describe("same-origin guest proxy", () => {
  it("forwards only the expected request data and preserves the constrained cookie", async () => {
    const fetcher = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
      expect(String(input)).toBe("https://edge.example/functions/v1/guest-invite");
      expect(init?.redirect).toBe("manual");
      expect(new Headers(init?.headers).get("origin")).toBe("https://guest.example");
      expect(new Headers(init?.headers).get("cookie")).toBe("before_i_buy_guest_session=opaque");
      return new Response(JSON.stringify({ dilemma: {} }), { status: 200, headers: { "Set-Cookie": "before_i_buy_guest_session=opaque; Path=/functions/v1/guest-invite; HttpOnly; Secure; SameSite=Strict", "Cache-Control": "no-store", "Access-Control-Allow-Origin": "https://evil.example" } });
    });
    const request = new Request("https://guest.example/functions/v1/guest-invite", { method: "POST", headers: { Origin: "https://guest.example", Cookie: "before_i_buy_guest_session=opaque", "Content-Type": "application/json" }, body: "{}" });
    const response = await proxyGuestInvite(request, "/functions/v1/guest-invite", { edgeOrigin: "https://edge.example", fetcher });
    expect(response.status).toBe(200);
    expect(response.headers.get("set-cookie")).toContain("Path=/functions/v1/guest-invite");
    expect(response.headers.get("access-control-allow-origin")).toBeNull();
    expect(response.headers.get("cache-control")).toBe("no-store");
  });

  it("fails closed for invalid routes, methods, configuration, and upstream failures", async () => {
    const get = new Request("https://guest.example/functions/v1/guest-invite", { method: "GET" });
    expect((await proxyGuestInvite(get, "/functions/v1/guest-invite", { edgeOrigin: "https://edge.example" })).status).toBe(404);
    const post = new Request("https://guest.example/functions/v1/guest-invite", { method: "POST" });
    expect((await proxyGuestInvite(post, "/anything", { edgeOrigin: "https://edge.example" })).status).toBe(404);
    expect((await proxyGuestInvite(post, "/functions/v1/guest-invite", { edgeOrigin: "https://edge.example/path" })).status).toBe(404);
    expect((await proxyGuestInvite(post, "/functions/v1/guest-invite", { edgeOrigin: "https://edge.example", fetcher: async () => { throw new Error("offline"); } })).status).toBe(404);
  });

  it("rejects non-JSON and oversized bodies before contacting the upstream", async () => {
    const fetcher = vi.fn();
    const wrongType = new Request("https://guest.example/functions/v1/guest-invite", {
      method: "POST",
      headers: { "Content-Type": "text/plain" },
      body: "{}",
    });
    const oversized = new Request("https://guest.example/functions/v1/guest-invite", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ padding: "x".repeat(4096) }),
    });
    expect((await proxyGuestInvite(wrongType, "/functions/v1/guest-invite", { edgeOrigin: "https://edge.example", fetcher })).status).toBe(404);
    expect((await proxyGuestInvite(oversized, "/functions/v1/guest-invite", { edgeOrigin: "https://edge.example", fetcher })).status).toBe(404);
    expect(fetcher).not.toHaveBeenCalled();
  });
});
