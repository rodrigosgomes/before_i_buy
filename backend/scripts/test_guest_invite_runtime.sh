#!/usr/bin/env bash

set -euo pipefail

runtime_dir="$(mktemp -d)"
runtime_log="$runtime_dir/runtime.log"
runtime_env_file="$runtime_dir/functions.env"
response_headers="$runtime_dir/headers.txt"
response_body="$runtime_dir/body.txt"
vote_headers="$runtime_dir/vote-headers.txt"
vote_body="$runtime_dir/vote-body.txt"
revoked_vote_headers="$runtime_dir/revoked-vote-headers.txt"
revoked_vote_body="$runtime_dir/revoked-vote-body.txt"
runtime_owner_id="$(node -e "process.stdout.write(crypto.randomUUID())")"
runtime_dilemma_id="$(node -e "process.stdout.write(crypto.randomUUID())")"
runtime_invite_token="$(node -e "process.stdout.write(crypto.randomBytes(32).toString('base64url'))")"
runtime_rate_limit_secret="local-runtime-rate-limit-secret-32-bytes-minimum"
db_container="supabase_db_before-i-buy"

run_psql() {
  docker exec -i "$db_container" psql \
    -v ON_ERROR_STOP=1 \
    -U postgres \
    -d postgres \
    -Atq
}

cleanup() {
  if [[ -n "${runtime_pid:-}" ]]; then
    kill "$runtime_pid" 2>/dev/null || true
    wait "$runtime_pid" 2>/dev/null || true
  fi
  if [[ "${dilemma_seeded:-0}" == "1" ]]; then
    run_psql <<SQL >/dev/null 2>&1 || true
delete from public.dilemmas where id = '$runtime_dilemma_id';
delete from auth.users where id = '$runtime_owner_id';
SQL
  fi
  rm -rf "$runtime_dir"
}
trap cleanup EXIT

report_failure() {
  failure_code=$?
  echo "guest invite runtime smoke failed" >&2
  echo "readiness_status=${status:-unset}" >&2
  echo "open_status=${open_status:-unset}" >&2
  echo "open_limit_status=${open_limit_status:-unset}" >&2
  echo "repeated_open_attempt=${repeated_open_attempt:-unset}" >&2
  echo "repeated_open_status=${repeated_open_status:-unset}" >&2
  echo "vote_status=${vote_status:-unset}" >&2
  echo "vote_limit_status=${vote_limit_status:-unset}" >&2
  echo "repeated_vote_attempt=${repeated_vote_attempt:-unset}" >&2
  echo "repeated_vote_status=${repeated_vote_status:-unset}" >&2
  echo "revoked_vote_status=${revoked_vote_status:-unset}" >&2
  run_psql <<SQL >&2 || true
select 'diagnostic_sessions=' || count(*)
  from public.guest_access_sessions
 where dilemma_id = '$runtime_dilemma_id';
select 'diagnostic_rate_counters=' || count(*)
  from public.guest_rate_limits;
SQL
  sed -n '1,160p' "$runtime_log" >&2 || true
  return "$failure_code"
}
trap report_failure ERR

dilemma_seeded=1

run_psql <<SQL
select pg_notify('pgrst', 'reload schema');
insert into auth.users (id) values ('$runtime_owner_id');
insert into public.profiles (
  id, display_name, terms_accepted_version, privacy_accepted_version
) values ('$runtime_owner_id', 'Runtime owner', 'v1', 'v1');
insert into public.dilemmas (
  id, owner_id, item_name, price_cents, currency, category, purpose,
  reason, pause_duration_hours, pause_due_at, state, invite_token_hash,
  is_invite_revoked
) values (
  '$runtime_dilemma_id', '$runtime_owner_id', 'Runtime item', 10000, 'BRL',
  'other', 'for_self', 'Motivo valido para o smoke de runtime.', 24,
  now() + interval '1 day', 'collecting_votes',
  encode(extensions.digest('$runtime_invite_token', 'sha256'), 'hex'), false
);
SQL

printf 'GUEST_RATE_LIMIT_SECRET=%s\n' \
  "$runtime_rate_limit_secret" >"$runtime_env_file"
printf 'GUEST_WEB_ORIGIN=%s\n' \
  "http://127.0.0.1:56321" >>"$runtime_env_file"

SUPABASE_HOME="$runtime_dir/supabase-home" \
  ./node_modules/.bin/supabase functions serve --no-verify-jwt \
  --env-file "$runtime_env_file" \
  >"$runtime_log" 2>&1 &
runtime_pid=$!

for _attempt in $(seq 1 50); do
  status="$(curl --silent --show-error --connect-timeout 1 --max-time 2 \
    --dump-header "$response_headers" \
    --output "$response_body" \
    --write-out '%{http_code}' \
    --request POST \
    --header 'content-type: application/json' \
    --data '{"inviteToken":"not-a-valid-invite-token"}' \
    http://127.0.0.1:56321/functions/v1/guest-invite || true)"

  if [[ "$status" == "404" ]] \
    && grep -qi '^cache-control: no-store' "$response_headers" \
    && grep -qi '^referrer-policy: no-referrer' "$response_headers" \
    && grep -qi '^x-robots-tag: noindex, nofollow' "$response_headers"; then
    break
  fi

  sleep 0.2
done

test "${status:-}" = "404"
test "$(cat "$response_body")" = '{"error":"invite_unavailable"}'
! grep -qi '^set-cookie:' "$response_headers"

open_status="$(curl --silent --show-error --connect-timeout 1 --max-time 5 \
  --dump-header "$response_headers" \
  --output "$response_body" \
  --write-out '%{http_code}' \
  --request POST \
  --header 'origin: http://127.0.0.1:56321' \
  --header 'content-type: application/json' \
  --data "{\"inviteToken\":\"$runtime_invite_token\"}" \
  http://127.0.0.1:56321/functions/v1/guest-invite)"

test "$open_status" = "200"
grep -q "\"dilemma_id\":\"$runtime_dilemma_id\"" "$response_body"
session_cookie="$(
  grep -i '^set-cookie:' "$response_headers" \
    | sed -E 's/^[Ss]et-[Cc]ookie:[[:space:]]*//' \
    | cut -d';' -f1 \
    | tr -d '\r'
)"
test -n "$session_cookie"

# The first request above consumed slot 1. Requests 2-30 remain successful;
# request 31 must fail generically and must not issue a session cookie.
for _attempt in $(seq 2 30); do
  repeated_open_attempt="$_attempt"
  sleep 0.1
  repeated_open_status="$(curl --silent --show-error --connect-timeout 1 --max-time 5 \
    --dump-header "$response_headers" \
    --output "$response_body" \
    --write-out '%{http_code}' \
    --request POST \
    --header 'origin: http://127.0.0.1:56321' \
    --header 'content-type: application/json' \
    --data "{\"inviteToken\":\"$runtime_invite_token\"}" \
    http://127.0.0.1:56321/functions/v1/guest-invite)"
  test "$repeated_open_status" = "200"
done

open_limit_status="$(curl --silent --show-error --connect-timeout 1 --max-time 5 \
  --dump-header "$response_headers" \
  --output "$response_body" \
  --write-out '%{http_code}' \
  --request POST \
  --header 'origin: http://127.0.0.1:56321' \
  --header 'content-type: application/json' \
  --data "{\"inviteToken\":\"$runtime_invite_token\"}" \
  http://127.0.0.1:56321/functions/v1/guest-invite)"

test "$open_limit_status" = "429"
test "$(cat "$response_body")" = '{"error":"invite_unavailable"}'
! grep -qi '^set-cookie:' "$response_headers"

vote_status="$(curl --silent --show-error --connect-timeout 1 --max-time 5 \
  --dump-header "$vote_headers" \
  --output "$vote_body" \
  --write-out '%{http_code}' \
  --request POST \
  --header 'origin: http://127.0.0.1:56321' \
  --header 'content-type: application/json' \
  --header "cookie: $session_cookie" \
  --data "{\"dilemmaId\":\"$runtime_dilemma_id\",\"prediction\":\"buy\"}" \
  http://127.0.0.1:56321/functions/v1/guest-invite/vote)"

test "$vote_status" = "200"
test "$(cat "$vote_body")" = \
  '{"vote":{"prediction":"buy","changed":false},"aggregates":{"buy":1,"wait":0,"skip":0,"total":1}}'
grep -qi '^cache-control: no-store' "$vote_headers"
grep -qi '^referrer-policy: no-referrer' "$vote_headers"
grep -qi '^x-robots-tag: noindex, nofollow' "$vote_headers"
! grep -qi '^set-cookie:' "$vote_headers"

# The vote above consumed slot 1. Exercise the real Edge/HMAC/RPC chain through
# slot 10, then ensure slot 11 is rejected without mutating the persisted vote.
for _attempt in $(seq 2 10); do
  repeated_vote_attempt="$_attempt"
  sleep 0.1
  if (( _attempt % 2 == 0 )); then
    repeated_prediction="wait"
  else
    repeated_prediction="buy"
  fi
  repeated_vote_status="$(curl --silent --show-error --connect-timeout 1 --max-time 5 \
    --dump-header "$vote_headers" \
    --output "$vote_body" \
    --write-out '%{http_code}' \
    --request POST \
    --header 'origin: http://127.0.0.1:56321' \
    --header 'content-type: application/json' \
    --header "cookie: $session_cookie" \
    --data "{\"dilemmaId\":\"$runtime_dilemma_id\",\"prediction\":\"$repeated_prediction\"}" \
    http://127.0.0.1:56321/functions/v1/guest-invite/vote)"
  test "$repeated_vote_status" = "200"
done

vote_limit_status="$(curl --silent --show-error --connect-timeout 1 --max-time 5 \
  --dump-header "$vote_headers" \
  --output "$vote_body" \
  --write-out '%{http_code}' \
  --request POST \
  --header 'origin: http://127.0.0.1:56321' \
  --header 'content-type: application/json' \
  --header "cookie: $session_cookie" \
  --data "{\"dilemmaId\":\"$runtime_dilemma_id\",\"prediction\":\"skip\"}" \
  http://127.0.0.1:56321/functions/v1/guest-invite/vote)"

test "$vote_limit_status" = "429"
test "$(cat "$vote_body")" = '{"error":"vote_unavailable"}'
! grep -qi '^set-cookie:' "$vote_headers"
test "$(run_psql <<SQL
select v.prediction::text
  from public.votes v
  join public.participations p on p.id = v.participation_id
 where p.dilemma_id = '$runtime_dilemma_id';
SQL
)" = "wait"

run_psql <<SQL >/dev/null
begin;
select set_config('request.jwt.claim.sub', '$runtime_owner_id', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;
select public.revoke_dilemma_invite('$runtime_dilemma_id');
commit;
delete from public.guest_rate_limits where scope = 'invite_open';
SQL

revoked_vote_status="$(curl --silent --show-error --connect-timeout 1 --max-time 5 \
  --dump-header "$revoked_vote_headers" \
  --output "$revoked_vote_body" \
  --write-out '%{http_code}' \
  --request POST \
  --header 'origin: http://127.0.0.1:56321' \
  --header 'content-type: application/json' \
  --header "cookie: $session_cookie" \
  --data "{\"dilemmaId\":\"$runtime_dilemma_id\",\"prediction\":\"skip\"}" \
  http://127.0.0.1:56321/functions/v1/guest-invite/vote)"

test "$revoked_vote_status" = "404"
test "$(cat "$revoked_vote_body")" = '{"error":"vote_unavailable"}'

revoked_open_status="$(curl --silent --show-error --connect-timeout 1 --max-time 5 \
  --dump-header "$response_headers" \
  --output "$response_body" \
  --write-out '%{http_code}' \
  --request POST \
  --header 'origin: http://127.0.0.1:56321' \
  --header 'content-type: application/json' \
  --data "{\"inviteToken\":\"$runtime_invite_token\"}" \
  http://127.0.0.1:56321/functions/v1/guest-invite)"

test "$revoked_open_status" = "404"
test "$(cat "$response_body")" = '{"error":"invite_unavailable"}'
! grep -qi '^set-cookie:' "$response_headers"
