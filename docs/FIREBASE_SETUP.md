# Firebase setup on the free Spark plan

The application uses the existing project `bookstore-fe6f2`.
The user requires free services only. Keep Spark; no billing upgrade or Cloud
Functions deployment is required by the current implementation.

## Applied setup — 13 October 2026

- Confirmed the active default database in `us-central1`:
  `https://bookstore-fe6f2-default-rtdb.firebaseio.com`.
- Enabled and read back Email/Password Authentication.
- Granted the existing verified `aptechschemework@gmail.com` account the
  `admin: true` custom claim, preserving other claims.
- Deployed the initial Phase 1 rules and read back an exact match. The final
  Phase 3 rules were also read back on 13 October 2026 and exactly match local rules.
- Added six sample books using conditional writes that preserve existing books.
- Preserved both existing registration profiles.
- Added `.firebaserc` so local commands select the correct project.

The administrator should sign out and sign back in with the existing account
password so the app receives the new token claim. No passwords were changed.
Device-level login, restart and checkout checks remain separate verification.

Pre-change database/rules/auth-setting backups and the setup verification
record are stored under `.firebase/setup-backups/`, which is excluded from Git.
These backups contain private registration data; keep them local.

## Authentication and administrator

1. Enable Email/Password in Firebase Authentication.
2. Register and verify a real account through the app. The old hardcoded
   administrator email/password no longer bypass Firebase.
3. The selected bootstrap owner is `aptechschemework@gmail.com`, UID
   `6W2W5WzGMiWG6580Q5ET4iS4y903`. Its existing server-issued `{admin: true}`
   claim initializes administrator access. `account_policy.dart` and database
   rules protect this UID. Preserve existing claims when maintaining this account.
4. Sign in as that owner. Use Manage users to grant another existing account a
   bookstore admin role. Protected `/accountAccess/{uid}` flags grant other
   administrators access; arbitrary custom claims or editable profile `role`
   fields do not grant app privileges. Each administrator must be email-verified.

Bootstrap maintenance example for a trusted Node.js Admin SDK environment:

```js
const ownerUid = '6W2W5WzGMiWG6580Q5ET4iS4y903';
const user = await getAuth().getUser(ownerUid);
await getAuth().setCustomUserClaims(ownerUid, {
  ...(user.customClaims ?? {}), admin: true,
});
```

Do not add service account keys, passwords or private credentials to this repo.
The selected existing account was promoted during the owner-authorized setup.

## Realtime Database

1. Confirm the actual database URL in Firebase Console. Update
   `AuthService.databaseUrl` if it differs from the confirmed default URL.
2. Review `database.rules.json` and deploy to your development project:

```powershell
firebase deploy --only database --project YOUR_DEVELOPMENT_PROJECT
```

3. At the `/books` node, import `fixtures/catalog.json` using Firebase Console's
   Import JSON action, only into an empty development catalog. Importing JSON
   replaces data at the selected location. The fixture contains the original six
   demo books; release dates are placeholders and must be corrected before
   relying on release-date sorting.
4. Register two verified customer accounts. Add different carts/wishlists,
   switch accounts, restart the app and confirm each customer's data is isolated.
5. Place a Cash on Delivery order, then change its status using the admin
   account. Verify the customer's history updates and survives app restart.

## Data layout

| Path | Purpose | Access |
| --- | --- | --- |
| `/users/{uid}` | Registration profile | Own profile; admin can list |
| `/accountAccess/{uid}` | Protected role/block/removal flags | Own read; admin list/manage other non-owner accounts |
| `/books/{bookId}` | Shared catalog | Verified users read; admins write |
| `/customerData/{uid}/cart/{bookId}` | Quantity from 1 to 99 | Owner only |
| `/customerData/{uid}/cart/_version` | Monotonic cart version | Owner transaction / checkout |
| `/customerData/{uid}/cart/_epoch` | Cart lifetime identity | Owner initializes; immutable during lifetime |
| `/customerData/{uid}/wishlist/{bookId}` | Saved book flag | Owner only |
| `/customerData/{uid}/addresses/{id}` | Shipping addresses | Owner only |
| `/customerData/{uid}/paymentMethods/{id}` | Brand, last four digits and expiry only | Owner only |
| `/customerData/{uid}/preferences` | Theme and notification preferences | Owner only |
| `/customerData/{uid}/orderReadStatus/{orderId}` | Acknowledged real order status | Order owner only |
| `/bookReviews/{bookId}/{uid}` | Rating and comment | Verified active read; author writes |
| `/reviewLikes/{bookId}/{reviewUid}/{voterUid}` | Unique voter flag | Verified active read; voter writes |
| `/orders/{orderId}` | Immutable owner and book/price snapshot | Owner query; admins read |
| `/orders/{orderId}/status` | Shared delivery status | Admin writes |

Order creation, removal of purchased cart entries and cart version advancement
use one atomic multi-location update. The UI confirms the saved receipt after
that write is acknowledged. A cart version/epoch change rejects stale checkout;
stable order IDs prevent another receipt for the same reviewed cart.
Historical orders retain their book snapshot when the catalog changes.
All shop access requires active membership. Admin removal atomically clears
the target's saved customer data and sets removed/blocked flags; it preserves
registration profiles, orders and Authentication identities. Restoration grants
customer access with no recovery of the cleared saved data. Permanent Auth
deletion is performed by the owner in Firebase Console if required.

Statuses: Ordered → Processing → Shipped → Out for delivery → Delivered.

## Local rule verification

Firebase CLI and Java 21+ are required. The test script rejects non-local hosts
and uses the `demo-bookstore` project to avoid live data.

```powershell
firebase emulators:exec --only database --project demo-bookstore --config firebase.emulators.json "node tools/test_database_rules.mjs"
```

On this machine, Android Studio's `jbr` contains a compatible Java runtime;
prepend its `bin` directory to `PATH` for the test process if the default Java
is older. Firebase CLI selects `java` from `PATH`.

## Remaining limits

- Phase 2 added persistent profiles, addresses, safe card references,
  preferences and reviews/likes. Its updated rules were reported deployed.
- Admin user management uses Spark database rules and does not depend on Cloud
  Functions. The latest free-plan rules were reported released successfully;
  a separate read-back confirmed the exact local match after the CLI shutdown error.
- Combined verification is deferred per user instruction. See [Phase 2](PHASE_2.md).
- Checkout uses Cash on Delivery. Profile card references cannot charge a card.
- Phase 3 adds catalog/cart checks and integer-cent line/subtotal/total validation
  in Spark rules, with up to 20 different books per order and the SAVE10 promotion.
- Versioned carts, lifetime IDs and atomic checkout handle competing cart writes
  and duplicate submissions. Multi-device behavior checks remain queued.
- Order alerts and a read/unread inbox work through in-app subscriptions; no
  background push or email sender is configured. See [Phase 3](PHASE_3.md).
- Mobile Firebase configuration exists for Android and iOS. Web/desktop Firebase
  configurations have not been generated or verified.

Implementation references: [Flutter database writes and streams](https://firebase.google.com/docs/database/flutter/read-and-write),
[database access conditions](https://firebase.google.com/docs/database/security/rules-conditions).
