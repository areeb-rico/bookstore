# Book Store implementation phases

Project constraint: use free services only. Keep Firebase Spark; do not buy a
plan, enable billing or introduce paid deployment requirements. All combined
verification remains deferred until Phase 5, as requested by the user.

## Phase 1 — persistent catalog, customer data and orders (local implementation verified)
- Replace the in-memory catalog with Realtime Database subscriptions.
- Store cart and wishlist under each Firebase UID.
- Save order snapshots with their owner and clear the cart atomically.
- Clear subscriptions and local data when the signed-in account changes.
- Replace the static administrator bypass with verified Firebase login and a protected admin role.
- Add database rules, setup instructions and focused tests.

Completed locally:
- Live catalog, per-UID cart/wishlist and owner-filtered order subscriptions.
- Acknowledged atomic Cash on Delivery order creation and cart clearing.
- Account switch/logout clears local state and cancels old subscriptions.
- Verified Firebase admin login using a server-issued custom claim; working logout.
- Persistent book CRUD and admin status changes; all five tracking statuses agree.
- Android Internet permission and release-date-based sorting.
- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: 12 tests passed.
- Realtime Database demo-emulator suite: 36 rules checks passed.

Firebase setup applied on 13 October 2026:
- Confirmed the URL, deployed reviewed rules and inserted the six-book catalog.
- Enabled Email/Password sign-in and configured the owner-selected verified administrator.
- Verified deployed rules and authentication configuration by reading them back.

Still required to verify Phase 1 on a device:
- Verify two accounts, restart persistence and admin/customer status sync on a device.
- Database rules and catalog have been deployed. See [Firebase setup](FIREBASE_SETUP.md).

## Phase 2 — profiles, reviews and administration (implemented; verification pending)
- Persist profile changes, addresses, preferences and reviews/likes.
- Store only safe payment metadata; never store PAN or CVV.
- Complete bookstore membership management using protected Spark database rules.
- Complete catalog editing (cover, description, genre and release date).
- Expand order administration with valid forward status transitions and detailed order views.

Implemented on 13 October 2026:
- Persistent profile edits, verified email-change flow, address CRUD and safe card references.
- Per-user preferences and live profile/account data subscriptions.
- Persisted reviews and voter-owned likes; book detail averages use live reviews.
- Full book editor, catalog-driven genres and detailed live order views.
- Forward-only order status transactions and matching database rules.
- Spark admin management: roles, block/unblock access, remove/restore membership;
  protected owner/self, live access changes and customer saved-data removal.
- Authentication identities remain; permanent Auth deletion is a Firebase Console
  owner action. Registration profiles and order history remain for administration.
- Removed Cloud Functions dependencies/configuration and the unused card checkout form.
- Phase 2 database rules were reported released by Firebase CLI. The CLI then hit
  its Windows shutdown assertion; final read-back is queued with combined verification.

The user requires Spark permanently for this eProject. Account management uses
the database and does not require a callable deployment or a purchased plan.
Billing has not been enabled.

Per user instruction, analyzer/tests/emulator/device checks for these changes
are deferred to the combined Phase 5 verification. See [Phase 2 details](PHASE_2.md).

## Phase 3 — checkout and order updates on free services (implemented; verification pending)
- Finish Cash on Delivery checkout, delivery contact and saved-address selection.
- Strengthen database validation of catalog snapshots, quantities and prices;
  define a checkout model whose total can be checked within Spark rules.
- Handle stale catalog/cart data and repeated submissions clearly.
- Add in-app order-status notifications using existing database subscriptions.
- Use administrator-managed delivery statuses for this eProject. Live bank payment,
  paid delivery APIs, provider webhooks and paid server deployments are outside
  the free project scope; do not display them as working integrations.

Implemented:
- Typed checkout quotes, saved-address selection, validated delivery contact and
  optional address persistence after acknowledgement.
- Cash on Delivery review and receipt screens; slow-save state and stable retries.
- User-requested saved-card checkout: create/select a payment method in checkout
  or profile, retain masked metadata in orders, and confirm only acknowledged
  orders. No bank charge or paid status is fabricated. See [payment methods](PAYMENT_METHODS.md).
- Integer-cent price, line, subtotal and SAVE10 total checks in database rules.
  Each order is bounded to 20 different books for explicit rule summation.
- Cart transactions with versions and lifetime IDs; atomic checkout rejects stale
  data, consumes only purchased entries and preserves history across restoration.
- Live in-app order alerts, notification inbox and persistent read/unread state.
- Prepared updated Flutter and local rules tests; not executed per user instruction.
- Firebase CLI reported the final Phase 3 rules valid and released successfully;
  it then hit the existing Windows shutdown assertion. A separate authorized
  read-back on 13 October 2026 confirmed an exact match with local rules (exit 0).

See [Phase 3 details](PHASE_3.md). Formatting and deployed-rule read-back are
complete; combined app verification remains a Phase 5 task.

## Phase 4 — UI finishing (pending)
User instruction: do not start Phase 4 yet. No Phase 4 implementation was begun
during the separate rules read-back task.

- Apply dark theme consistently, improve responsive layouts and accessibility.
- Complete placeholder actions and real release-date/bestseller sorting.
- Show useful loading, empty and error states throughout the app.

## Phase 5 — verification and submission (pending)
- At the user's separate request, the Android release APK was built successfully
  on 13 October 2026. Package and signature checks passed; see
  [Android build record](ANDROID_BUILD.md). App behavior verification remains pending.
- Run combined verification after implementation, as requested by the user.
- Run analyzer, automated tests and Android build checks.
- Validate deployed Firebase rules and two-account isolation on a device/emulator.
- Write developer setup, user guide, project report and a demonstration script.
- Record the working video after live flows have been verified.

Status is updated with evidence after each phase; local implementation does not imply that Firebase configuration has been deployed.
