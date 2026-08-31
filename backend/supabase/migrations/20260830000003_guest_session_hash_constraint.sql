-- The session secret is a SHA-256 hex digest, never a raw client secret.

alter table public.guest_access_sessions
  add constraint guest_access_sessions_secret_hash_is_sha256
  check (session_secret_hash ~ '^[0-9a-f]{64}$');
