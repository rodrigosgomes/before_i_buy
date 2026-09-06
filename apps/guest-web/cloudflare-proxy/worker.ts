import { proxyGuestInvite } from "../src/lib/proxy";

export interface Env {
  GUEST_INVITE_EDGE_ORIGIN: string;
}

const worker = {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    return proxyGuestInvite(request, url.pathname, {
      edgeOrigin: env.GUEST_INVITE_EDGE_ORIGIN,
    });
  },
};

export default worker;
