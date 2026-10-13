import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const host = process.env.FIREBASE_DATABASE_EMULATOR_HOST;
if (!host || !/^(localhost|127\.0\.0\.1):\d+$/.test(host)) {
  throw new Error('Run only through firebase emulators:exec against localhost.');
}
const project = 'demo-bookstore';
const namespace = `${project}-default-rtdb`;
const base = `http://${host}`;
function token(uid, extras = {}) {
  const now = Math.floor(Date.now() / 1000);
  const encode = data => Buffer.from(JSON.stringify(data)).toString('base64url');
  return `${encode({ alg: 'none', typ: 'JWT' })}.${encode({
    iss: `https://securetoken.google.com/${project}`, aud: project,
    auth_time: now, user_id: uid, sub: uid, iat: now, exp: now + 3600,
    email: `${uid}@example.test`, email_verified: true,
    firebase: { identities: {}, sign_in_provider: 'password' }, ...extras,
  })}.`;
}
async function request(path, method = 'GET', value, auth, query = {}) {
  const url = new URL(`${base}/${path}.json`);
  url.searchParams.set('ns', namespace);
  // REST ID tokens use `auth`. Bearer OAuth tokens are treated as service
  // account credentials by the emulator and would bypass the tested rules.
  if (auth && auth !== 'owner') url.searchParams.set('auth', auth);
  for (const [key, val] of Object.entries(query)) url.searchParams.set(key, JSON.stringify(val));
  const response = await fetch(url, {
    method, headers: { 'Content-Type': 'application/json', ...(auth === 'owner' ? { Authorization: 'Bearer owner' } : {}) },
    body: value === undefined ? undefined : JSON.stringify(value),
    signal: AbortSignal.timeout(10000),
  });
  return { status: response.status, data: await response.json() };
}
let checks = 0;
async function allowed(label, path, method, value, auth, query) {
  const result = await request(path, method, value, auth, query);
  assert.equal(result.status, 200, `${label}: ${JSON.stringify(result)}`);
  checks++; return result.data;
}
async function denied(label, path, method, value, auth, query) {
  const result = await request(path, method, value, auth, query);
  assert.ok([401, 403].includes(result.status), `${label}: ${JSON.stringify(result)}`);
  checks++;
}

const rules = JSON.parse(await readFile(new URL('../database.rules.json', import.meta.url), 'utf8'));
const catalog = JSON.parse(await readFile(new URL('../fixtures/catalog.json', import.meta.url), 'utf8'));
const ownerUid = '6W2W5WzGMiWG6580Q5ET4iS4y903';
const profile = uid => ({ uid, name: uid === 'alice' ? 'Alice' : 'Reader', email: `${uid}@example.test`, phone: '03001234567', role: 'Customer', createdAt: '2026-10-13' });
const flags = { admin: false, disabled: false, removed: false };
await allowed('load rules', '.settings/rules', 'PUT', rules, 'owner');
await allowed('seed isolated emulator', '', 'PUT', { books: catalog, users: { admin: profile('admin'), bob: profile('bob'), [ownerUid]: profile(ownerUid) }, accountAccess: { admin: { ...flags, admin: true } } }, 'owner');
const alice = token('alice'), bob = token('bob'), admin = token('admin'), bootstrap = token(ownerUid, { admin: true });
const unverified = token('unverified', { email_verified: false });
await denied('anonymous catalog', 'books', 'GET');
await denied('unverified catalog', 'books', 'GET', undefined, unverified);
await allowed('verified catalog', 'books', 'GET', undefined, alice);
await denied('customer edits catalog', 'books/1/title', 'PUT', 'Tampered', alice);
await denied('arbitrary custom claim grants no membership', 'books/1/title', 'PUT', 'Tampered', token('bob', { admin: true }));
await allowed('membership admin edits catalog', 'books/1/title', 'PUT', 'Updated Title', admin);
await allowed('bootstrap owner catalog', 'books', 'GET', undefined, bootstrap);
await allowed('create own profile', 'users/alice', 'PUT', profile('alice'), alice);
await denied('self-promote metadata', 'users/alice/role', 'PUT', 'Admin', alice);
await denied('self-promote access', 'accountAccess/alice', 'PUT', { ...flags, admin: true }, alice);
await denied('admin changes itself', 'accountAccess/admin', 'PUT', { ...flags, disabled: true }, admin);
await denied('admin changes bootstrap owner', `accountAccess/${ownerUid}`, 'PUT', { ...flags, removed: true, disabled: true }, admin);
await denied('other profile', 'users/alice', 'GET', undefined, bob);
await denied('list users as customer', 'users', 'GET', undefined, alice);
await allowed('list users as admin', 'users', 'GET', undefined, admin);
await allowed('initial versioned cart', 'customerData/alice/cart', 'PUT', { 1: 2, _version: 1, _epoch: 'legacy' }, alice);
await denied('other cart read', 'customerData/alice', 'GET', undefined, bob);
await denied('unversioned cart edit', 'customerData/alice/cart/1', 'PUT', 3, alice);
await denied('reset entire cart version', 'customerData/alice/cart', 'DELETE', undefined, alice);
for (const [label, cart] of [
  ['fractional quantity', { 1: 1.5, _version: 2, _epoch: 'legacy' }],
  ['excessive quantity', { 1: 100, _version: 2, _epoch: 'legacy' }],
  ['unknown book', { missing: 1, _version: 2, _epoch: 'legacy' }],
  ['epoch changed in existing cart', { 1: 2, _version: 2, _epoch: '-O123456789012345678' }],
]) await denied(label, 'customerData/alice/cart', 'PUT', cart, alice);
await allowed('own wishlist', 'customerData/alice/wishlist/1', 'PUT', true, alice);
await denied('other wishlist', 'customerData/alice/wishlist/1', 'PUT', true, bob);
const snapshot = { ...catalog['1'], title: 'Updated Title' };
const unit = Math.round(snapshot.price * 100), subtotal = unit * 2;
const order = { schemaVersion: 2, userId: 'alice', total: subtotal / 100, totalMinor: subtotal, subtotalMinor: subtotal, promoCode: '', cartRevision: 1, cartEpoch: 'legacy', shippingAddress: 'House 12, Gulshan, Karachi', deliveryContact: { name: 'Alice', phone: '03001234567', address: 'House 12', area: 'Gulshan', city: 'Karachi' }, status: 'Ordered', date: '2026-10-13T12:00:00.000Z', paymentMethod: 'Cash', items: { 0: { bookId: '1', book: snapshot, quantity: 2, unitPriceMinor: unit, lineTotalMinor: subtotal } } };
const atomic = (record, { revision = 2, id = 'alice-legacy-1' } = {}) => ({ [`orders/${id}`]: record, 'customerData/alice/cart/1': null, 'customerData/alice/cart/_version': revision, 'customerData/alice/cart/_epoch': 'legacy' });
await allowed('customer can read own absent receipt', 'orders/alice-legacy-1', 'GET', undefined, alice);
await denied('wrong owner', '', 'PATCH', atomic({ ...order, userId: 'bob' }), alice);
await denied('fake paid card', '', 'PATCH', atomic({ ...order, paymentMethod: 'Card' }), alice);
await denied('missing delivery contact', '', 'PATCH', atomic({ ...order, deliveryContact: null }), alice);
await denied('forged price snapshot', '', 'PATCH', atomic({ ...order, items: { 0: { ...order.items[0], book: { ...snapshot, price: .01 } } } }), alice);
await denied('forged quantity', '', 'PATCH', atomic({ ...order, items: { 0: { ...order.items[0], quantity: 1, lineTotalMinor: unit } }, subtotalMinor: unit, totalMinor: unit, total: unit / 100 }), alice);
await denied('forged line total', '', 'PATCH', atomic({ ...order, items: { 0: { ...order.items[0], lineTotalMinor: 1 } } }), alice);
await denied('forged grand total', '', 'PATCH', atomic({ ...order, total: .01, totalMinor: 1 }), alice);
await denied('unauthorized promotion', '', 'PATCH', atomic({ ...order, promoCode: 'FREE' }), alice);
await denied('duplicate book lines', '', 'PATCH', atomic({ ...order, items: { 0: order.items[0], 1: order.items[0] }, subtotalMinor: subtotal * 2, totalMinor: subtotal * 2, total: subtotal * 2 / 100 }), alice);
await denied('line beyond bounded twenty slots', '', 'PATCH', atomic({ ...order, items: { 0: order.items[0], 20: order.items[0] } }), alice);
await denied('order without consuming the cart', 'orders/alice-legacy-1', 'PUT', order, alice);
assert.equal(await allowed('cart retained after failed checks', 'customerData/alice/cart/1', 'GET', undefined, alice), 2);
// Another device changes the quantity. A quote from revision 1 cannot clear it.
await allowed('second device changes cart', 'customerData/alice/cart', 'PUT', { 1: 3, _version: 2, _epoch: 'legacy' }, alice);
await denied('stale quote rejected atomically', '', 'PATCH', atomic(order), alice);
assert.equal(await allowed('new quantity retained', 'customerData/alice/cart/1', 'GET', undefined, alice), 3);
const freshSubtotal = unit * 3, freshTotal = Math.floor((freshSubtotal * 90 + 50) / 100);
const fresh = { ...order, cartRevision: 2, promoCode: 'SAVE10', subtotalMinor: freshSubtotal, totalMinor: freshTotal, total: freshTotal / 100, items: { 0: { ...order.items[0], quantity: 3, lineTotalMinor: freshSubtotal } } };
await allowed('validated SAVE10 atomic checkout', '', 'PATCH', atomic(fresh, { revision: 3, id: 'alice-legacy-2' }), alice);
assert.equal(await allowed('ordered book removed', 'customerData/alice/cart/1', 'GET', undefined, alice), null);
assert.equal(await allowed('version retained', 'customerData/alice/cart/_version', 'GET', undefined, alice), 3);
await denied('same receipt cannot be created twice', '', 'PATCH', atomic(fresh, { revision: 3, id: 'alice-legacy-2' }), alice);
await denied('read another order', 'orders/alice-legacy-2', 'GET', undefined, bob);
await denied('unfiltered customer orders', 'orders', 'GET', undefined, alice);
const own = await allowed('filtered own orders', 'orders', 'GET', undefined, alice, { orderBy: 'userId', equalTo: 'alice' });
assert.equal(own['alice-legacy-2'].userId, 'alice');
await denied('query another customer', 'orders', 'GET', undefined, bob, { orderBy: 'userId', equalTo: 'alice' });
await denied('customer changes status', 'orders/alice-legacy-2/status', 'PUT', 'Processing', alice);
await denied('skip delivery steps', 'orders/alice-legacy-2/status', 'PUT', 'Delivered', admin);
await allowed('admin advances one step', 'orders/alice-legacy-2/status', 'PUT', 'Processing', admin);
await denied('reverse status', 'orders/alice-legacy-2/status', 'PUT', 'Ordered', admin);
await allowed('customer acknowledges real status', 'customerData/alice/orderReadStatus/alice-legacy-2', 'PUT', 'Processing', alice);
await denied('other customer acknowledges status', 'customerData/alice/orderReadStatus/alice-legacy-2', 'PUT', 'Processing', bob);
await denied('fabricated read status', 'customerData/alice/orderReadStatus/alice-legacy-2', 'PUT', 'Delivered', alice);
await allowed('grant admin through flags', 'accountAccess/bob', 'PUT', { ...flags, admin: true }, admin);
await allowed('promoted admin lists users', 'users', 'GET', undefined, bob);
await allowed('demote admin immediately', 'accountAccess/bob', 'PUT', flags, admin);
await denied('demoted account loses admin permissions', 'users', 'GET', undefined, bob);
await allowed('block customer', 'accountAccess/alice', 'PUT', { ...flags, disabled: true }, admin);
await denied('blocked customer catalog access', 'books', 'GET', undefined, alice);
await allowed('blocked customer can observe own access', 'accountAccess/alice', 'GET', undefined, alice);
await allowed('unblock customer', 'accountAccess/alice', 'PUT', flags, admin);
await allowed('remove bookstore membership and saved data', '', 'PATCH', { 'accountAccess/alice': { ...flags, disabled: true, removed: true }, 'customerData/alice': null }, admin);
await denied('removed customer catalog access', 'books', 'GET', undefined, alice);
await allowed('order preserved for administration', 'orders/alice-legacy-2', 'GET', undefined, admin);
await allowed('restore customer membership', 'accountAccess/alice', 'PUT', flags, admin);
await allowed('restored cart has new lifetime identity', 'customerData/alice/cart', 'PUT', { 1: 1, _version: 1, _epoch: '-O123456789012345678' }, alice);
// Old snapshots remain valid for status changes after a catalog edit/deletion.
await allowed('catalog price changes', 'books/1/price', 'PUT', 20, admin);
await allowed('historical snapshot retained during tracking', 'orders/alice-legacy-2/status', 'PUT', 'Shipped', admin);
await allowed('delete catalog book', 'books/1', 'DELETE', undefined, admin);
await allowed('deleted catalog book does not break historical tracking', 'orders/alice-legacy-2/status', 'PUT', 'Out for delivery', admin);
await denied('delete historical order', 'orders/alice-legacy-2', 'DELETE', undefined, admin);
console.log(`Passed ${checks} Realtime Database rules checks against the local demo emulator.`);
