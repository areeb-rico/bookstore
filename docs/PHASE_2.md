# Phase 2 implementation — 13 October 2026

User instruction: defer combined tests, emulator checks and device verification
until all implementation phases are ready. Phase 2 changes have not been
claimed as tested. Formatting and dependency setup are implementation steps.

## Customer data

- Name and phone update the existing `/users/{uid}` registration record.
- Email changes reauthenticate with the current password and use Firebase's
  verification-before-update flow. The profile email syncs on the next login.
- Addresses support create, edit and remove at
  `/customerData/{uid}/addresses/{addressId}`.
- Card references persist only brand, last four digits and expiry at
  `/customerData/{uid}/paymentMethods/{referenceId}`. They are not payment tokens.
  Full card numbers and CVV are neither collected nor stored by the profile UI.
- Dark mode and notification/email preferences persist under
  `/customerData/{uid}/preferences`. In-app alerts were connected in Phase 3.
- Account changes cancel subscriptions and discard previous account state.

## Reviews and catalog

- One review per customer/book, editable by its author, at
  `/bookReviews/{bookId}/{uid}`.
- Review likes use one boolean per voter under
  `/reviewLikes/{bookId}/{reviewUid}/{voterUid}`. Customers cannot change another
  voter's entry or edit another customer's review.
- Book detail averages/counts are calculated from live persisted reviews.
- Book editor supports title, author, price, genre, HTTPS cover URL, description
  and release date. Genres in customer filters follow the catalog.
- The six sample books still need real release dates; Phase 2 does not invent
  publication dates or replace existing catalog records automatically.

## Orders

- Admin order detail view shows immutable book/quantity/price snapshots, owner,
  date, address, payment method and total.
- Status changes proceed one step at a time:
  Ordered → Processing → Shipped → Out for delivery → Delivered.
- A transaction prevents a stale admin screen from moving the status backwards.
- Customer history/detail views subscribe to the live order state.

## Account management on Firebase Spark

The user requires free services only, with no purchased plans or billing
upgrades. `AdminService` now uses Realtime Database directly; Cloud Functions
have been removed from the application dependency and deployment configuration.

- Admins list bookstore registration profiles, grant/revoke bookstore admin
  roles, block/unblock access, and remove/restore bookstore membership.
- Rules protect `/accountAccess/{uid}` flags (`admin`, `disabled`, `removed`).
  Customers cannot edit these flags or grant themselves privileges.
- The selected bootstrap owner uses its existing server-issued admin claim.
  Other app admins use protected database flags. Editable profile role metadata
  never grants access; rules check the current membership on every operation.
- The bootstrap owner and acting administrator are protected against their
  own in-app demotion, block and removal.
- An active session listens for membership changes. Blocking/removing signs
  it out; role changes switch the available dashboard. Rules remain authoritative
  even if the app is offline or using stale local state.
- Removal clears saved customer data (cart, wishlist, addresses, card references
  and preferences), marks access removed/blocked, and revokes its bookstore role.
  Registration profiles, orders and Firebase Authentication identities remain.
  Restoration restores customer access; it does not recreate cleared saved data.
- Permanent deletion of an Authentication identity is an owner operation in
  Firebase Console. The in-app removal action does not claim to delete it.

Firebase CLI reported the Spark rules released successfully on 13 October 2026.
It then encountered the existing Windows shutdown assertion. The later final
Phase 3 rules were separately read back and matched on 13 October 2026; behavior
checks remain queued for combined verification. Billing was not
enabled and there is no pending paid backend deployment.

Checkout now offers Cash on Delivery and saved-card selection. Profile and checkout
share the **Create payment method** form; only brand, last four digits and expiry
are saved. No payment token, full number or CVV is stored, and no bank charge is
processed. See [payment methods](PAYMENT_METHODS.md).
