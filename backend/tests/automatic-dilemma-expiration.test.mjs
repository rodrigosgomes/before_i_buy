import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import test from "node:test";

const dbContainer = "supabase_db_before-i-buy";

function runPsql(sql) {
  return new Promise((resolve, reject) => {
    const child = spawn("docker", [
      "exec", "-i", dbContainer, "psql", "-v", "ON_ERROR_STOP=1",
      "-U", "postgres", "-d", "postgres", "-Atq",
    ]);
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => { stdout += chunk; });
    child.stderr.on("data", (chunk) => { stderr += chunk; });
    child.on("error", reject);
    child.on("close", (code) => {
      if (code === 0) resolve(stdout.trim());
      else reject(new Error(`psql exited ${code}: ${stderr}`));
    });
    child.stdin.end(sql);
  });
}

const delay = (milliseconds) =>
  new Promise((resolve) => setTimeout(resolve, milliseconds));

test("the real cron expires a dilemma and preserves its vote", async (t) => {
  const ownerId = crypto.randomUUID();
  const dilemmaId = crypto.randomUUID();
  const token = `${crypto.randomUUID().replaceAll("-", "")}EXPIRESCRON`;
  const secret = "S".repeat(43);

  t.after(async () => {
    await runPsql(`delete from auth.users where id = '${ownerId}';`)
      .catch(() => {});
  });

  const seeded = await runPsql(`
    insert into auth.users (id) values ('${ownerId}');
    insert into public.profiles (
      id, display_name, terms_accepted_version, privacy_accepted_version
    ) values ('${ownerId}', 'Cron owner', 'v1', 'v1');
    insert into public.dilemmas (
      id, owner_id, item_name, price_cents, currency, category, purpose,
      reason, pause_duration_hours, pause_due_at, state, invite_token_hash,
      is_invite_revoked
    ) values (
      '${dilemmaId}', '${ownerId}', 'Cron item', 10000, 'BRL', 'other',
      'for_self', 'Motivo valido para expiracao automatica.', 24,
      clock_timestamp() + interval '5 seconds', 'collecting_votes',
      encode(extensions.digest('${token}', 'sha256'), 'hex'), false
    );
    select count(*) from public.open_guest_invite_session(
      '${token}', '${secret}',
      encode(extensions.digest('runtime-open-${dilemmaId}', 'sha256'), 'hex')
    );
    select count(*) from public.submit_guest_vote(
      '${dilemmaId}', '${secret}', 'buy',
      encode(extensions.digest('runtime-vote-${dilemmaId}', 'sha256'), 'hex')
    );
  `);
  assert.deepEqual(seeded.split("\n"), ["1", "1"]);

  const deadline = Date.now() + 120_000;
  let state = "collecting_votes";
  while (Date.now() < deadline) {
    state = await runPsql(`
      select state::text from public.dilemmas where id = '${dilemmaId}';
    `);
    if (state === "decision_due") break;
    await delay(1_000);
  }
  assert.equal(state, "decision_due", "cron must expire within 120 seconds");

  const preserved = await runPsql(`
    select
      d.state::text || '|' || count(p.id) || '|' || count(v.id) || '|'
      || count(v.id) filter (where v.prediction = 'buy')
    from public.dilemmas d
    left join public.participations p on p.dilemma_id = d.id
    left join public.votes v on v.participation_id = p.id
    where d.id = '${dilemmaId}'
    group by d.id;
    begin;
    set local request.jwt.claim.sub = '${ownerId}';
    set local request.jwt.claim.role = 'authenticated';
    set local role authenticated;
    select state::text || '|' || buy_count || '|' || wait_count || '|'
      || skip_count || '|' || total_votes
      from public.get_creator_dilemmas()
     where dilemma_id = '${dilemmaId}';
    commit;
    select count(*) from public.open_guest_invite_session(
      '${token}', '${"N".repeat(43)}',
      encode(extensions.digest('expired-open-${dilemmaId}', 'sha256'), 'hex')
    );
    select count(*) from public.submit_guest_vote(
      '${dilemmaId}', '${secret}', 'wait',
      encode(extensions.digest('expired-vote-${dilemmaId}', 'sha256'), 'hex')
    );
  `);
  assert.deepEqual(preserved.split("\n"), [
    "decision_due|1|1|1",
    "decision_due|1|0|0|1",
    "0",
    "0",
  ]);
});
