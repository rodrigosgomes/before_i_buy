#!/usr/bin/env bash

set -euo pipefail

runtime_dir="$(mktemp -d)"
runtime_log="$runtime_dir/runtime.log"
response_headers="$runtime_dir/headers.txt"
response_body="$runtime_dir/body.txt"

cleanup() {
  if [[ -n "${runtime_pid:-}" ]]; then
    kill "$runtime_pid" 2>/dev/null || true
    wait "$runtime_pid" 2>/dev/null || true
  fi
  rm -rf "$runtime_dir"
}
trap cleanup EXIT

SUPABASE_HOME="$runtime_dir/supabase-home" \
  ./node_modules/.bin/supabase functions serve --no-verify-jwt \
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
