import { proxyGuestInvite } from "../../../../src/lib/proxy";

export async function POST(request: Request) {
  return proxyGuestInvite(request, "/functions/v1/guest-invite");
}
