import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

const root = fileURLToPath(new URL('../../', import.meta.url));
const status = spawnSync(resolve(root, 'backend/node_modules/.bin/supabase'),
  ['status', '--output', 'json'], { cwd: resolve(root, 'backend'), encoding: 'utf8' });
if (status.status !== 0) throw new Error('Local Supabase is unavailable. Start and migrate the local stack.');
const config = JSON.parse(status.stdout);
if (config.API_URL !== 'http://127.0.0.1:56321' || !config.ANON_KEY || !config.SERVICE_ROLE_KEY) {
  throw new Error('Refusing a non-local or incomplete Supabase test configuration.');
}
// Local credentials stay in the test process environment, never in the app,
// output, persisted config, or Flutter build defines.
const test = spawnSync('flutter', ['test', '--reporter', 'expanded',
  'test/system/creator_supabase_test.dart'], {
  cwd: resolve(root, 'apps/mobile'), stdio: 'inherit',
  env: { ...process.env, LOCAL_SUPABASE_ANON_KEY: config.ANON_KEY,
    LOCAL_SUPABASE_SERVICE_ROLE_KEY: config.SERVICE_ROLE_KEY },
});
process.exitCode = test.status ?? 1;
