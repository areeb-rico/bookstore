// Owner-operated setup for this project's existing Firebase CLI session.
// Credentials stay inside firebase-tools; this script never prints tokens.
const path = require('node:path');
const fs = require('node:fs/promises');
const assert = require('node:assert/strict');
const { createHash } = require('node:crypto');
const project = 'bookstore-fe6f2';
const bootstrapOwnerUid = '6W2W5WzGMiWG6580Q5ET4iS4y903';
const cliRoot = process.env.FIREBASE_TOOLS_DIR || path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib');
const { getProjectDefaultAccount } = require(path.join(cliRoot, 'auth.js'));
const { requireAuth } = require(path.join(cliRoot, 'requireAuth.js'));
const { Client } = require(path.join(cliRoot, 'apiv2.js'));
const { identityOrigin } = require(path.join(cliRoot, 'api.js'));

async function main() {
  const mode = process.argv[2] || 'inspect';
  const account = getProjectDefaultAccount(process.cwd());
  if (!account) throw new Error('Sign in with firebase login first.');
  await requireAuth({ project, projectId: project, user: account.user, tokens: account.tokens, nonInteractive: true });
  const client = new Client({ urlPrefix: identityOrigin(), auth: true });
  const database = new Client({ urlPrefix: 'https://bookstore-fe6f2-default-rtdb.firebaseio.com', auth: true });
  if (mode === 'verify-rules') {
    const reportPrefix = (process.argv.find(arg => arg.startsWith('--report-prefix=')) || '--report-prefix=phase-3-rules').split('=')[1];
    if (!/^[a-z0-9-]+$/.test(reportPrefix)) throw new Error('Invalid report prefix.');
    const remote = (await database.get('/.settings/rules.json')).body;
    const parsed = typeof remote === 'string' ? JSON.parse(remote) : remote;
    const localText = await fs.readFile('database.rules.json', 'utf8');
    const local = JSON.parse(localText);
    assert.deepEqual(parsed, local, 'Deployed rules differ from the local rules');
    const canonical = value => Array.isArray(value) ? value.map(canonical) : value && typeof value === 'object'
      ? Object.fromEntries(Object.keys(value).sort().map(key => [key, canonical(value[key])])) : value;
    const report = {
      checkedAt: new Date().toISOString(), project,
      databaseUrl: 'https://bookstore-fe6f2-default-rtdb.firebaseio.com',
      deployedRulesMatch: true,
      localFileSha256: createHash('sha256').update(localText).digest('hex'),
      canonicalRulesSha256: createHash('sha256').update(JSON.stringify(canonical(parsed))).digest('hex'),
      scope: 'Read-only deployed-rules comparison; no app behavior tests or Phase 4 work.',
    };
    const reportDir = path.resolve('.firebase/setup-backups');
    await fs.mkdir(reportDir, { recursive: true });
    await fs.writeFile(path.join(reportDir, `${reportPrefix}-remote.json`), JSON.stringify(parsed, null, 2));
    await fs.writeFile(path.join(reportDir, `${reportPrefix}-readback.json`), JSON.stringify(report, null, 2));
    console.log(JSON.stringify(report));
    return;
  }
  const configPath = `/admin/v2/projects/${project}/config`;
  const config = (await client.get(configPath, { headers: { 'x-goog-user-project': project } })).body;
  const list = (await client.post(`/v1/projects/${project}/accounts:query`, { limit: '500', offset: '0' }, {
    queryParams: { fields: 'userInfo(localId,email,emailVerified,displayName,disabled,customAttributes),recordsCount' },
  })).body;
  const users = (list.userInfo || []).map(user => ({
    uid: user.localId, email: user.email || '', name: user.displayName || '',
    verified: user.emailVerified === true, disabled: user.disabled === true,
    claims: JSON.parse(user.customAttributes || '{}'),
  }));
  const backupDir = path.resolve('.firebase/setup-backups');
  await fs.mkdir(backupDir, { recursive: true });
  if (mode === 'seed-catalog') {
    const catalog = JSON.parse(await fs.readFile('fixtures/catalog.json', 'utf8'));
    const inserted = [], preserved = [];
    for (const [id, book] of Object.entries(catalog)) {
      const route = `/books/${id}.json`;
      const current = await database.get(route, { headers: { 'X-Firebase-ETag': 'true' } });
      if (current.body !== null) { preserved.push(id); continue; }
      const result = await database.request({
        method: 'PUT', path: route, body: book,
        headers: { 'If-Match': current.response.headers.get('etag') },
        resolveOnHTTPError: true,
      });
      if (result.status === 412) { preserved.push(id); continue; }
      assert.equal(result.status, 200, `Catalog insert failed for ${id}`);
      inserted.push(id);
    }
    const remote = (await database.get('/books.json')).body;
    await fs.writeFile(path.join(backupDir, 'catalog-after.json'), JSON.stringify(remote, null, 2));
    console.log(JSON.stringify({ project, insertedBookIds: inserted, preservedBookIds: preserved,
      catalogCount: Object.values(remote || {}).filter(Boolean).length }));
    return;
  }
  if (mode === 'inspect') {
    // Store only the settings that may be changed here; no provider secrets.
    await fs.writeFile(path.join(backupDir, 'auth-before.json'), JSON.stringify({
      project, emailSignIn: config.signIn?.email || {},
      authorizedDomains: config.authorizedDomains || [], users,
    }, null, 2), { flag: 'wx' }).catch(error => {
      if (error.code !== 'EEXIST') throw error;
    });
  }
  if (mode === 'enable-email') {
    if (!config.signIn?.email?.enabled || !config.signIn?.email?.passwordRequired) {
      await client.patch(configPath, { signIn: { email: { enabled: true, passwordRequired: true } } }, {
        queryParams: { updateMask: 'signIn.email.enabled,signIn.email.passwordRequired' },
        headers: { 'x-goog-user-project': project },
      });
    }
    const fresh = (await client.get(configPath)).body;
    assert.equal(fresh.signIn.email.enabled, true);
    assert.equal(fresh.signIn.email.passwordRequired, true);
    console.log(JSON.stringify({ project, emailPasswordEnabled: true }));
    return;
  }
  if (mode === 'promote-admin') {
    const email = process.argv[3];
    if (!email) throw new Error('An explicitly selected administrator email is required.');
    const user = users.find(u => u.email.toLowerCase() === email.toLowerCase());
    if (!user) throw new Error('The selected account must already exist in Firebase Authentication.');
    if (user.disabled || !user.verified) throw new Error('The selected account must be enabled and email-verified.');
    if (user.uid === bootstrapOwnerUid) {
      await fs.writeFile(path.join(backupDir, 'admin-claims-before.json'), JSON.stringify({ uid: user.uid, email: user.email, claims: user.claims }, null, 2), { flag: 'wx' }).catch(error => {
        if (error.code !== 'EEXIST') throw error;
      });
      await client.post('/v1/accounts:update', {
        targetProjectId: project, localId: user.uid,
        customAttributes: JSON.stringify({ ...user.claims, admin: true }),
      });
      const fresh = (await client.post(`/v1/projects/${project}/accounts:lookup`, { localId: [user.uid] }, {
        queryParams: { fields: 'users(localId,email,emailVerified,customAttributes)' },
      })).body.users[0];
      assert.equal(JSON.parse(fresh.customAttributes || '{}').admin, true);
      console.log(JSON.stringify({ project, adminEmail: fresh.email, bootstrapClaimVerified: true }));
    } else {
      const profile = (await database.get(`/users/${user.uid}.json`)).body;
      if (!profile || profile.uid !== user.uid) throw new Error('Register this account in the bookstore first.');
      const route = `/accountAccess/${user.uid}.json`;
      const current = await database.get(route, { headers: { 'X-Firebase-ETag': 'true' } });
      if (current.body?.disabled === true || current.body?.removed === true) {
        throw new Error('Restore or unblock bookstore access before granting an admin role.');
      }
      const result = await database.request({
        method: 'PUT', path: route,
        body: { admin: true, disabled: false, removed: false },
        headers: { 'If-Match': current.response.headers.get('etag') },
        resolveOnHTTPError: true,
      });
      assert.equal(result.status, 200, 'Access changed concurrently; refresh and retry.');
      console.log(JSON.stringify({ project, adminEmail: user.email, bookstoreAdminGranted: true }));
    }
    return;
  }
  if (mode !== 'inspect' && mode !== 'verify') throw new Error('Unsupported setup mode.');
  if (mode === 'inspect') {
    console.log(JSON.stringify({ project, emailSignIn: config.signIn?.email || {},
      authorizedDomains: config.authorizedDomains || [], users }, null, 2));
    return;
  }
  const liveRules = (await database.get('/.settings/rules.json')).body;
  // The rules response may be a JSON string with comments from Firebase.
  const local = JSON.parse(await fs.readFile('database.rules.json', 'utf8'));
  const parsed = typeof liveRules === 'string' ? JSON.parse(liveRules) : liveRules;
  assert.deepEqual(parsed, local, 'Deployed rules must match the reviewed local rules');
  const live = (await database.get('/.json')).body || {};
  const original = JSON.parse(await fs.readFile(path.join(backupDir, 'database-before.json'), 'utf8')) || {};
  for (const uid of Object.keys(original.users || {})) {
    assert.equal(live.users?.[uid]?.uid, uid, 'Original registration profile IDs must remain available');
  }
  // Phase 2 permits legitimate name/phone/email edits and new registrations.
  // Exact original-profile comparison is only useful immediately after setup.
  if (process.argv.includes('--strict-profiles')) {
    assert.deepEqual(live.users || {}, original.users || {}, 'Original profiles must match in strict setup mode');
  }
  const verifiedAdminEmails = users.filter(user => {
    const access = live.accountAccess?.[user.uid] || {};
    return user.verified && !user.disabled && access.disabled !== true && access.removed !== true &&
      (access.admin === true || (user.uid === bootstrapOwnerUid && user.claims.admin === true));
  }).map(user => user.email);
  const anonymousChecks = {};
  for (const node of ['books', 'users', 'orders', 'customerData', 'accountAccess']) {
    const response = await fetch(`https://bookstore-fe6f2-default-rtdb.firebaseio.com/${node}.json`, {
      signal: AbortSignal.timeout(15000),
    });
    assert.ok([401, 403].includes(response.status), `Anonymous access must be blocked at ${node}`);
    anonymousChecks[node] = response.status;
  }
  if (mode === 'verify') {
    await fs.writeFile(path.join(backupDir, 'setup-verification.json'), JSON.stringify({
      checkedAt: new Date().toISOString(), project, databaseUrl: 'https://bookstore-fe6f2-default-rtdb.firebaseio.com',
      deployedRulesMatch: true, emailPasswordEnabled: config.signIn?.email?.enabled === true && config.signIn?.email?.passwordRequired === true,
      catalogCount: Object.values(live.books || {}).filter(Boolean).length,
      profileCount: Object.keys(live.users || {}).length,
      existingProfileIdsPreserved: true, anonymousChecks, verifiedAdminEmails,
    }, null, 2));
  }
  console.log(JSON.stringify({ project, deployedRulesMatch: true,
    existingProfileIdsPreserved: true, anonymousChecks, verifiedAdminEmails,
    catalogCount: Object.values(live.books || {}).filter(Boolean).length,
    profileCount: Object.keys(live.users || {}).length, emailSignIn: config.signIn?.email || {},
    authorizedDomains: config.authorizedDomains || [], users }, null, 2));
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
