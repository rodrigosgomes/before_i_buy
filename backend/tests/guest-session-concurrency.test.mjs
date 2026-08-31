import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import test from "node:test";

const dbContainer = "supabase_db_before-i-buy";

function runPsql(sql) {
  return new Promise((resolve, reject) => {
    const child = spawn("docker", [
      "exec",
      "-i",
      dbContainer,
      "psql",
      "-v",
      "ON_ERROR_STOP=1",
      "-U",
      "postgres",
      "-d",
      "postgres",
      "-Atq",
    ]);
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => { stdout += chunk; });
    child.stderr.on("data", (chunk) => { stderr += chunk; });
    child.on("error", reject);
    child.on("close", (code) => {
      if (code === 0) {
        resolve(stdout.trim());
      } else {
        reject(new Error(`psql exited ${code}: ${stderr}`));
      }
    });
    child.stdin.end(sql);
  });
}

function waitForOutput(stream, expected) {
  return new Promise((resolve, reject) => {
    let output = "";
    const timeout = setTimeout(() => {
      reject(new Error(`timed out waiting for ${expected}; output: ${output}`));
    }, 5_000);
    stream.on("data", (chunk) => {
      output += chunk;
      if (output.includes(expected)) {
        clearTimeout(timeout);
        resolve();
      }
    });
  });
}

function delay(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

test("revocation serializes with invite opening and leaves no usable session", async (t) => {
  const suffix = crypto.randomUUID();
  const ownerId = crypto.randomUUID();
  const dilemmaId = crypto.randomUUID();
  const token = `invite-token-${suffix}`;
  const secret = "A".repeat(43);

  await runPsql(`
    insert into auth.users (id) values ('${ownerId}');
    insert into public.profiles (
      id, display_name, terms_accepted_version, privacy_accepted_version
    ) values ('${ownerId}', 'Concurrency owner', 'v1', 'v1');
    insert into public.dilemmas (
      id, owner_id, item_name, price_cents, currency, category, purpose,
      reason, pause_duration_hours, pause_due_at, state, invite_token_hash,
      is_invite_revoked
    ) values (
      '${dilemmaId}', '${ownerId}', 'Concurrency camera', 100000, 'BRL',
      'tech_electronics', 'for_self', 'Dilema de concorrencia seguro.', 24,
      now() + interval '1 day', 'collecting_votes',
      encode(extensions.digest('${token}', 'sha256'), 'hex'), false
    );
  `);

  t.after(async () => {
    await runPsql(`delete from public.dilemmas where id = '${dilemmaId}';`)
      .catch(() => {});
    await runPsql(`delete from auth.users where id = '${ownerId}';`)
      .catch(() => {});
  });

  const locker = spawn("docker", [
    "exec",
    "-i",
    dbContainer,
    "psql",
    "-v",
    "ON_ERROR_STOP=1",
    "-U",
    "postgres",
    "-d",
    "postgres",
    "-Atq",
  ]);
  let lockerStderr = "";
  locker.stderr.on("data", (chunk) => { lockerStderr += chunk; });
  t.after(() => {
    if (!locker.killed) {
      locker.kill("SIGINT");
    }
  });

  locker.stdin.write(`
    begin;
    select id from public.dilemmas where id = '${dilemmaId}' for update;
    select 'LOCK_ACQUIRED';
  `);
  await waitForOutput(locker.stdout, "LOCK_ACQUIRED");

  let openingSettled = false;
  const opening = runPsql(`
    select count(*)
      from public.open_guest_invite_session('${token}', '${secret}');
  `).then((result) => {
    openingSettled = true;
    return result;
  });

  await delay(150);
  assert.equal(openingSettled, false, "invite opening waits for the revocation lock");

  locker.stdin.end(`
    update public.dilemmas set is_invite_revoked = true where id = '${dilemmaId}';
    commit;
  `);

  assert.equal(await opening, "0");
  assert.equal(
    await runPsql(`
      select count(*)
        from public.guest_access_sessions
       where dilemma_id = '${dilemmaId}';
    `),
    "0",
  );
  assert.equal(lockerStderr, "");
});
