# Phase 3 — checkout and order updates

Implemented on 13 October 2026 using the existing Firebase Spark project.
No purchased plan, billing upgrade, Cloud Functions, payment provider or delivery
API was introduced. Tests, analyzer and emulator/device checks remain deferred
to the combined Phase 5 verification. The user separately requested deployed-rule
read-back, which completed successfully on 13 October 2026.

## Checkout

- Cash on Delivery is the only payment method. No online charge is simulated.
- Delivery name, normalized phone, house/street, area and city are stored as an
  immutable `deliveryContact` snapshot, alongside the formatted address.
- Customers can select a saved address or enter one, and optionally save the
  entered address after a confirmed order. An address-save failure cannot place
  another order; the receipt remains confirmed.
- The review screen shows the exact book/quantity/price snapshot, promotion and
  total. Checkout requires an online connection and waits for write acknowledgement.
- Cart/catalog changes before submission require a return to the cart to review
  the latest data. Removed books can be cleared from the cart explicitly.
- Pending saves disable repeated taps, cart edits, dismissal and delivery edits.
  Slow saves show a waiting message; there is no timeout that falsely confirms
  or cancels an order while a write may still be pending.
- A failed attempt retains its original reviewed quote and delivery details.
  Retry uses the same order identity and returns the actual existing receipt
  if another attempt already succeeded. Receipt totals/contacts come from that
  saved order, not a later edited form.

## Price and total validation on Spark

New orders use schema version 2. Unit prices are rounded to cents, line totals
are integer unit cents × quantity, and all totals use integer cents. `SAVE10`
is the only promotion; the discounted total rounds half cents upward. Delivery
has no additional fee in this eProject.

Database rules require catalog-matching book snapshots, quantities matching the
reviewed cart, unique book lines, valid contact fields, correct line totals,
the calculated subtotal and the authorized final total. The decimal `total`
field is retained for existing views and must agree with `totalMinor`.

Realtime Database rule snapshots do not provide a general summation operation.
The implementation bounds each order to 20 different books (1–99 copies each)
and explicitly sums the 20 permitted line slots. Extra slots, duplicate book
lines, forged prices and arbitrary discounts have explicit rejection conditions
in the rules; behavior verification is still queued.
This is a concrete rule-enforced model and needs no paid server. See the
[Firebase rule API](https://firebase.google.com/docs/reference/security/database).

Historical Phase 1/2 orders remain readable, and admin status updates preserve
their original snapshot when catalog books change or are deleted.

## Cart concurrency and retry identity

Cart quantities remain at `/customerData/{uid}/cart/{bookId}`. Two reserved
metadata entries are added:

- `_version`: incremented by every cart transaction and acknowledged checkout.
- `_epoch`: the lifetime identity of this cart; preserved until membership
  removal clears customer data. Restored customers receive a new lifetime ID
  on their next cart write, preventing collision with historical receipts.

Existing carts without metadata use the `legacy` identity and version 0 until
their first mutation. No live customer data is rewritten as a migration step.
The new application must be used with these rules: previous app versions wrote
unversioned quantities and no longer satisfy the new checkout/cart rules.

Order IDs use `uid-epoch-version`. Rules validate the expected cart version and
epoch and their post-write values. One atomic update creates the immutable order,
removes only purchased entries and advances the cart version. A competing cart
mutation rejects the entire checkout instead of wiping newer changes. A second
submission for the same reviewed cart cannot create another receipt.

## In-app notifications

- Existing order subscriptions detect changes to the current account's statuses.
  Initial history and another account's orders do not trigger alert banners.
- The Home bell and Profile notification entry open a live order inbox with
  tracking details, latest status, totals and unread indicators.
- `/customerData/{uid}/orderReadStatus/{orderId}` stores the acknowledged status.
  Rules allow only the order owner to acknowledge a currently valid status.
- A later status change becomes unread again. Account switching clears this
  local metadata. The saved preference controls alerts while using the app.
- These are in-app updates. Background push, emails and courier delivery tracking
  are not represented as implemented integrations. Admins advance delivery status.

## Prepared verification (not run)

- Updated controller/widget tests for typed checkout requests and saved receipts.
- Added quote rounding, promotion/line limits, snapshot and delivery tests.
- Added controller checks for order-alert isolation and quiet initial history.
- Updated the local-only demo database-rule suite for ownership, protected admin
  flags, forged amounts, duplicate lines, stale carts, retries, removal/restoration,
  read acknowledgements and historical status updates after catalog edits/deletion.
- Final queue: run analyzer, Flutter tests, emulator rules suite, Android build
  and two-device checkout/restart scenarios in Phase 5. Repeat rule read-back
  if a later phase changes the rules.

Firebase CLI reported the final Phase 3 rules syntactically valid and released
successfully on 13 October 2026. The process then exited with the existing
Windows `UV_HANDLE_CLOSING` shutdown assertion.

The owner-authorized read-back on 13 October 2026 at 12:18:54 UTC succeeded:
the deployed JSON rules exactly match the local `database.rules.json` structure
and values. `node tools/firebase_setup.cjs verify-rules` exited with code 0.
The local rules SHA-256 was
`7956cc5c17bec200bdd26fd841b83c825ab79db868f860d3ec556a473934ba04`.
The remote snapshot and comparison record are saved locally under the ignored
`.firebase/setup-backups/phase-3-rules-remote.json` and
`.firebase/setup-backups/phase-3-rules-readback.json`.

This confirms that the shutdown error did not prevent the final rules release.
App behavior tests remain queued. Phase 4 was not started, as requested.
