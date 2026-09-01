import { createClient } from "jsr:@supabase/supabase-js@2";

import {
  createRateLimitKey,
  handleGuestInviteRequest,
} from "./handler.mjs";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const rateLimitSecret = Deno.env.get("GUEST_RATE_LIMIT_SECRET");
const configuredGuestWebOrigin = Deno.env.get("GUEST_WEB_ORIGIN");

if (
  !supabaseUrl ||
  !serviceRoleKey ||
  !rateLimitSecret ||
  !configuredGuestWebOrigin
) {
  throw new Error(
    "SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, GUEST_RATE_LIMIT_SECRET, and GUEST_WEB_ORIGIN are required.",
  );
}

const guestWebUrl = new URL(configuredGuestWebOrigin);
const isLocalOrigin = ["localhost", "127.0.0.1"].includes(guestWebUrl.hostname);
if (
  guestWebUrl.origin !== configuredGuestWebOrigin ||
  (guestWebUrl.protocol !== "https:" && !isLocalOrigin)
) {
  throw new Error(
    "GUEST_WEB_ORIGIN must be one exact HTTPS origin without path, query, or fragment.",
  );
}
const guestWebOrigin = guestWebUrl.origin;

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

Deno.serve((request) =>
  handleGuestInviteRequest(request, {
    allowedOrigin: guestWebOrigin,
    deriveRateLimitKey: async (scope, subject) => {
      try {
        return await createRateLimitKey(scope, subject, rateLimitSecret);
      } catch (error) {
        console.error(JSON.stringify({
          event: "guest_rate_limit_hmac_failed",
          code: error instanceof Error ? error.name : "unknown",
        }));
        throw error;
      }
    },
    openGuestInviteSession: async (
      inviteToken,
      sessionSecret,
      rateLimitKey,
    ) => {
      const { data, error } = await supabase.rpc("open_guest_invite_session", {
        p_invite_token_plain: inviteToken,
        p_session_secret_plain: sessionSecret,
        p_rate_limit_key_hash: rateLimitKey,
      });

      if (error) {
        console.error(JSON.stringify({
          event: "guest_invite_open_rpc_failed",
          code: error.code ?? "unknown",
        }));
        return null;
      }

      return Array.isArray(data) ? data[0] ?? null : data;
    },
    submitGuestVote: async (
      dilemmaId,
      sessionSecret,
      prediction,
      rateLimitKey,
    ) => {
      const { data, error } = await supabase.rpc("submit_guest_vote", {
        p_dilemma_id: dilemmaId,
        p_session_secret_plain: sessionSecret,
        p_prediction: prediction,
        p_rate_limit_key_hash: rateLimitKey,
      });

      if (error) {
        console.error(JSON.stringify({
          event: "guest_vote_submit_rpc_failed",
          code: error.code ?? "unknown",
        }));
        return null;
      }

      return Array.isArray(data) ? data[0] ?? null : data;
    },
  }),
);
