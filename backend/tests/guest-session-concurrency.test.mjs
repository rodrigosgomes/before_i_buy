import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import test, { after, before } from "node:test";

const dbContainer = "supabase_db_before-i-buy";

before(async () => {
  await runPsql(`
    select cron.alter_job(jobid, active := false)
      from cron.job where jobname = 'expire-due-dilemmas';
  `);
});

after(async () => {
  await runPsql(`
    select cron.alter_job(jobid, active := true)
      from cron.job where jobname = 'expire-due-dilemmas';
  `);
});

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

async function waitForBlockedCommand(
  commandFragment,
  dilemmaId,
  timeoutMilliseconds = 5_000,
) {
  const deadline = Date.now() + timeoutMilliseconds;
  while (Date.now() < deadline) {
    const blocked = await runPsql(`
      select count(*)
        from pg_stat_activity
       where pid <> pg_backend_pid()
         and wait_event_type = 'Lock'
         and query like '%${commandFragment}%'
         and query like '%${dilemmaId}%';
    `);
    if (blocked !== "0") return;
    await delay(25);
  }
  throw new Error(`${commandFragment} for ${dilemmaId} did not reach the lock`);
}

const waitForBlockedQuery = (dilemmaId, timeoutMilliseconds = 5_000) =>
  waitForBlockedCommand("submit_guest_vote", dilemmaId, timeoutMilliseconds);

test("revocation serializes with invite opening and leaves no usable session", async (t) => {
  const suffix = crypto.randomUUID();
  const ownerId = crypto.randomUUID();
  const dilemmaId = crypto.randomUUID();
  const token = `${suffix.replaceAll("-", "")}ABCDEFGHIJK`;
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
      from public.open_guest_invite_session(
        '${token}',
        '${secret}',
        encode(extensions.digest('open:${token}', 'sha256'), 'hex')
      );
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

test("concurrent predictions from one guest session leave one active vote", async (t) => {
  const suffix = crypto.randomUUID();
  const ownerId = crypto.randomUUID();
  const dilemmaId = crypto.randomUUID();
  const secret = "V".repeat(43);

  await runPsql(`
    insert into auth.users (id) values ('${ownerId}');
    insert into public.profiles (
      id, display_name, terms_accepted_version, privacy_accepted_version
    ) values ('${ownerId}', 'Concurrent voter owner', 'v1', 'v1');
    insert into public.dilemmas (
      id, owner_id, item_name, price_cents, currency, category, purpose,
      reason, pause_duration_hours, pause_due_at, state, invite_token_hash,
      is_invite_revoked
    ) values (
      '${dilemmaId}', '${ownerId}', 'Concurrent vote item', 100000, 'BRL',
      'tech_electronics', 'for_self', 'Dilema para votos concorrentes.', 24,
      now() + interval '1 day', 'collecting_votes',
      encode(extensions.digest('vote-token-${suffix}', 'sha256'), 'hex'), false
    );
    insert into public.guest_access_sessions (
      dilemma_id, session_secret_hash, expires_at
    ) values (
      '${dilemmaId}',
      encode(extensions.digest('${secret}', 'sha256'), 'hex'),
      now() + interval '1 day'
    );
  `);

  t.after(async () => {
    await runPsql(`delete from public.dilemmas where id = '${dilemmaId}';`)
      .catch(() => {});
    await runPsql(`delete from auth.users where id = '${ownerId}';`)
      .catch(() => {});
  });

  const results = await Promise.all([
    runPsql(`
      select prediction::text
        from public.submit_guest_vote(
          '${dilemmaId}', '${secret}', 'buy',
          encode(extensions.digest('vote:${secret}', 'sha256'), 'hex')
        );
    `),
    runPsql(`
      select prediction::text
        from public.submit_guest_vote(
          '${dilemmaId}', '${secret}', 'skip',
          encode(extensions.digest('vote:${secret}', 'sha256'), 'hex')
        );
    `),
  ]);

  assert.deepEqual(results.sort(), ["buy", "skip"]);
  assert.equal(
    await runPsql(`
      select count(*)
        from public.participations
       where dilemma_id = '${dilemmaId}';
    `),
    "1",
  );
  assert.equal(
    await runPsql(`
      select count(*)
        from public.votes v
        join public.participations p on p.id = v.participation_id
       where p.dilemma_id = '${dilemmaId}';
    `),
    "1",
  );
  assert.match(
    await runPsql(`
      select v.prediction::text
        from public.votes v
        join public.participations p on p.id = v.participation_id
       where p.dilemma_id = '${dilemmaId}';
    `),
    /^(buy|skip)$/,
  );
});

test("revocation serializes with vote submission and wins before persistence", async (t) => {
  const suffix = crypto.randomUUID();
  const ownerId = crypto.randomUUID();
  const dilemmaId = crypto.randomUUID();
  const secret = "R".repeat(43);

  await runPsql(`
    insert into auth.users (id) values ('${ownerId}');
    insert into public.profiles (
      id, display_name, terms_accepted_version, privacy_accepted_version
    ) values ('${ownerId}', 'Vote revocation owner', 'v1', 'v1');
    insert into public.dilemmas (
      id, owner_id, item_name, price_cents, currency, category, purpose,
      reason, pause_duration_hours, pause_due_at, state, invite_token_hash,
      is_invite_revoked
    ) values (
      '${dilemmaId}', '${ownerId}', 'Vote revocation item', 100000, 'BRL',
      'tech_electronics', 'for_self', 'Dilema para revogacao concorrente.', 24,
      now() + interval '1 day', 'collecting_votes',
      encode(extensions.digest('revoke-vote-token-${suffix}', 'sha256'), 'hex'), false
    );
    insert into public.guest_access_sessions (
      dilemma_id, session_secret_hash, expires_at
    ) values (
      '${dilemmaId}',
      encode(extensions.digest('${secret}', 'sha256'), 'hex'),
      now() + interval '1 day'
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
    if (!locker.killed) locker.kill("SIGINT");
  });

  locker.stdin.write(`
    begin;
    select id from public.dilemmas where id = '${dilemmaId}' for update;
    select 'LOCK_ACQUIRED';
  `);
  await waitForOutput(locker.stdout, "LOCK_ACQUIRED");

  let voteSettled = false;
  const vote = runPsql(`
    select count(*)
      from public.submit_guest_vote(
        '${dilemmaId}', '${secret}', 'buy',
        encode(extensions.digest('vote:${secret}', 'sha256'), 'hex')
      );
  `).then((result) => {
    voteSettled = true;
    return result;
  });

  await delay(150);
  assert.equal(voteSettled, false, "vote submission waits for the dilemma lock");

  locker.stdin.end(`
    update public.dilemmas set is_invite_revoked = true where id = '${dilemmaId}';
    commit;
  `);

  assert.equal(await vote, "0");
  assert.equal(
    await runPsql(`
      select count(*)
        from public.participations
       where dilemma_id = '${dilemmaId}';
    `),
    "0",
  );
  assert.equal(lockerStderr, "");
});

test("a vote waiting on a lock is rejected when the pause expires", async (t) => {
  const suffix = crypto.randomUUID();
  const ownerId = crypto.randomUUID();
  const dilemmaId = crypto.randomUUID();
  const secret = "E".repeat(43);

  await runPsql(`
    insert into auth.users (id) values ('${ownerId}');
    insert into public.profiles (
      id, display_name, terms_accepted_version, privacy_accepted_version
    ) values ('${ownerId}', 'Vote expiry owner', 'v1', 'v1');
    insert into public.dilemmas (
      id, owner_id, item_name, price_cents, currency, category, purpose,
      reason, pause_duration_hours, pause_due_at, state, invite_token_hash,
      is_invite_revoked
    ) values (
      '${dilemmaId}', '${ownerId}', 'Vote expiry item', 100000, 'BRL',
      'tech_electronics', 'for_self', 'Dilema para expiracao concorrente.', 24,
      clock_timestamp() + interval '2 seconds', 'collecting_votes',
      encode(extensions.digest('expiry-vote-token-${suffix}', 'sha256'), 'hex'), false
    );
    insert into public.guest_access_sessions (
      dilemma_id, session_secret_hash, expires_at
    ) values (
      '${dilemmaId}',
      encode(extensions.digest('${secret}', 'sha256'), 'hex'),
      clock_timestamp() + interval '2 seconds'
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
    if (!locker.killed) locker.kill("SIGINT");
  });

  locker.stdin.write(`
    begin;
    select id from public.dilemmas where id = '${dilemmaId}' for update;
    select 'LOCK_ACQUIRED';
  `);
  await waitForOutput(locker.stdout, "LOCK_ACQUIRED");

  const vote = runPsql(`
    select count(*)
      from public.submit_guest_vote(
        '${dilemmaId}', '${secret}', 'wait',
        encode(extensions.digest('vote:${secret}', 'sha256'), 'hex')
      );
  `);

  await waitForBlockedQuery(dilemmaId);
  await delay(2_100);
  assert.equal(await runPsql("select private.expire_due_dilemmas();"), "0");
  locker.stdin.end("commit;\n");

  const [voteResult, expirationResult] = await Promise.all([
    vote,
    runPsql("select private.expire_due_dilemmas();"),
  ]);
  assert.equal(voteResult, "0");
  assert.equal(expirationResult, "1");
  assert.equal(
    await runPsql(`
      select count(*)
        from public.participations
       where dilemma_id = '${dilemmaId}';
    `),
    "0",
  );
  assert.equal(
    await runPsql(`select state::text from public.dilemmas where id = '${dilemmaId}';`),
    "decision_due",
  );
  assert.equal(lockerStderr, "");
});

test("expiration skips a locked due dilemma and resumes it later", async (t) => {
  const ownerId = crypto.randomUUID();
  const dilemmaId = crypto.randomUUID();
  await runPsql(`
    insert into auth.users (id) values ('${ownerId}');
    insert into public.profiles (
      id, display_name, terms_accepted_version, privacy_accepted_version
    ) values ('${ownerId}', 'Locked expiry owner', 'v1', 'v1');
    insert into public.dilemmas (
      id, owner_id, item_name, price_cents, category, reason,
      pause_duration_hours, pause_due_at, state
    ) values (
      '${dilemmaId}', '${ownerId}', 'Locked expiry item', 10000, 'other',
      'Motivo valido para lote bloqueado.', 24,
      clock_timestamp() - interval '1 minute', 'collecting_votes'
    );
  `);
  t.after(async () => {
    await runPsql(`delete from auth.users where id = '${ownerId}';`)
      .catch(() => {});
  });

  const locker = spawn("docker", [
    "exec", "-i", dbContainer, "psql", "-v", "ON_ERROR_STOP=1",
    "-U", "postgres", "-d", "postgres", "-Atq",
  ]);
  let lockerStderr = "";
  locker.stderr.on("data", (chunk) => { lockerStderr += chunk; });
  t.after(() => { if (!locker.killed) locker.kill("SIGINT"); });
  locker.stdin.write(`
    begin;
    select id from public.dilemmas where id = '${dilemmaId}' for update;
    select 'LOCK_ACQUIRED';
  `);
  await waitForOutput(locker.stdout, "LOCK_ACQUIRED");

  assert.equal(await runPsql("select private.expire_due_dilemmas();"), "0");
  locker.stdin.end("commit;\n");
  await new Promise((resolve, reject) => {
    locker.on("close", (code) => code === 0 ? resolve() : reject(new Error(lockerStderr)));
  });
  assert.equal(await runPsql("select private.expire_due_dilemmas();"), "1");
  assert.equal(
    await runPsql(`select state::text from public.dilemmas where id = '${dilemmaId}';`),
    "decision_due",
  );
  assert.equal(lockerStderr, "");
});

test("revocation and expiration converge without reopening access", async (t) => {
  const ownerId = crypto.randomUUID();
  const dilemmaId = crypto.randomUUID();
  await runPsql(`
    insert into auth.users (id) values ('${ownerId}');
    insert into public.profiles (
      id, display_name, terms_accepted_version, privacy_accepted_version
    ) values ('${ownerId}', 'Revoke expiry owner', 'v1', 'v1');
    insert into public.dilemmas (
      id, owner_id, item_name, price_cents, category, reason,
      pause_duration_hours, pause_due_at, state
    ) values (
      '${dilemmaId}', '${ownerId}', 'Revoke expiry item', 10000, 'other',
      'Motivo valido para revogacao e expiracao.', 24,
      clock_timestamp() - interval '1 minute', 'collecting_votes'
    );
  `);
  t.after(async () => {
    await runPsql(`delete from auth.users where id = '${ownerId}';`)
      .catch(() => {});
  });

  const locker = spawn("docker", [
    "exec", "-i", dbContainer, "psql", "-v", "ON_ERROR_STOP=1",
    "-U", "postgres", "-d", "postgres", "-Atq",
  ]);
  locker.stdin.write(`
    begin;
    select id from public.dilemmas where id = '${dilemmaId}' for update;
    select 'LOCK_ACQUIRED';
  `);
  await waitForOutput(locker.stdout, "LOCK_ACQUIRED");

  const revoke = runPsql(`
    begin;
    select set_config('request.jwt.claim.sub', '${ownerId}', true);
    select set_config('request.jwt.claim.role', 'authenticated', true);
    set local role authenticated;
    select public.revoke_dilemma_invite('${dilemmaId}');
    commit;
  `);
  await waitForBlockedCommand("revoke_dilemma_invite", dilemmaId);
  assert.equal(await runPsql("select private.expire_due_dilemmas();"), "0");
  locker.stdin.end("commit;\n");
  await revoke;
  assert.equal(await runPsql("select private.expire_due_dilemmas();"), "1");
  assert.equal(
    await runPsql(`
      select state::text || '|' || is_invite_revoked::text
        from public.dilemmas where id = '${dilemmaId}';
    `),
    "decision_due|true",
  );
});

test("deletion racing expiration leaves no dilemma to reopen", async (t) => {
  const ownerId = crypto.randomUUID();
  const dilemmaId = crypto.randomUUID();
  await runPsql(`
    insert into auth.users (id) values ('${ownerId}');
    insert into public.profiles (
      id, display_name, terms_accepted_version, privacy_accepted_version
    ) values ('${ownerId}', 'Delete expiry owner', 'v1', 'v1');
    insert into public.dilemmas (
      id, owner_id, item_name, price_cents, category, reason,
      pause_duration_hours, pause_due_at, state
    ) values (
      '${dilemmaId}', '${ownerId}', 'Delete expiry item', 10000, 'other',
      'Motivo valido para exclusao e expiracao.', 24,
      clock_timestamp() - interval '1 minute', 'collecting_votes'
    );
  `);
  t.after(async () => {
    await runPsql(`delete from auth.users where id = '${ownerId}';`)
      .catch(() => {});
  });

  const locker = spawn("docker", [
    "exec", "-i", dbContainer, "psql", "-v", "ON_ERROR_STOP=1",
    "-U", "postgres", "-d", "postgres", "-Atq",
  ]);
  locker.stdin.write(`
    begin;
    select id from public.dilemmas where id = '${dilemmaId}' for update;
    select 'LOCK_ACQUIRED';
  `);
  await waitForOutput(locker.stdout, "LOCK_ACQUIRED");

  const deletion = runPsql(`
    begin;
    select set_config('request.jwt.claim.sub', '${ownerId}', true);
    select set_config('request.jwt.claim.role', 'authenticated', true);
    set local role authenticated;
    select public.delete_creator_dilemma('${dilemmaId}');
    commit;
  `);
  await waitForBlockedCommand("delete_creator_dilemma", dilemmaId);
  assert.equal(await runPsql("select private.expire_due_dilemmas();"), "0");
  locker.stdin.end("commit;\n");
  await deletion;
  assert.equal(await runPsql("select private.expire_due_dilemmas();"), "0");
  assert.equal(
    await runPsql(`select count(*) from public.dilemmas where id = '${dilemmaId}';`),
    "0",
  );
});

test("two concurrent expiration runs process one bounded backlog once", async (t) => {
  const ownerId = crypto.randomUUID();
  await runPsql(`
    insert into auth.users (id) values ('${ownerId}');
    insert into public.profiles (
      id, display_name, terms_accepted_version, privacy_accepted_version
    ) values ('${ownerId}', 'Concurrent expiry owner', 'v1', 'v1');
    insert into public.dilemmas (
      owner_id, item_name, price_cents, category, reason,
      pause_duration_hours, pause_due_at, state
    )
    select
      '${ownerId}', 'Concurrent expiry ' || series, 10000, 'other',
      'Motivo valido para expiracao simultanea.', 24,
      clock_timestamp() - interval '1 minute', 'collecting_votes'
    from generate_series(1, 1500) series;
  `);
  t.after(async () => {
    await runPsql(`delete from auth.users where id = '${ownerId}';`)
      .catch(() => {});
  });

  const counts = await Promise.all([
    runPsql("select private.expire_due_dilemmas();"),
    runPsql("select private.expire_due_dilemmas();"),
  ]);
  assert.equal(counts.map(Number).reduce((sum, count) => sum + count, 0), 1500);
  assert.ok(counts.every((count) => Number(count) <= 1000));
  assert.equal(
    await runPsql(`
      select count(*) from public.dilemmas
       where owner_id = '${ownerId}' and state = 'decision_due';
    `),
    "1500",
  );
  assert.equal(await runPsql("select private.expire_due_dilemmas();"), "0");
});
