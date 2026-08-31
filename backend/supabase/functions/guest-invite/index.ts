import { createClient } from "jsr:@supabase/supabase-js@2";

import { handleGuestInvite } from "./handler.mjs";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required.");
}

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

Deno.serve((request) =>
  handleGuestInvite(request, {
    openGuestInviteSession: async (inviteToken, sessionSecret) => {
      const { data, error } = await supabase.rpc("open_guest_invite_session", {
        p_invite_token_plain: inviteToken,
        p_session_secret_plain: sessionSecret,
      });

      if (error) {
        return null;
      }

      return Array.isArray(data) ? data[0] ?? null : data;
    },
  }),
);
