# Book Store eProject

Flutter book shopping application with customer and administrator screens,
Firebase Authentication and Firebase Realtime Database.

## Implementation status

Work is divided into five phases in [the implementation plan](docs/IMPLEMENTATION_PLAN.md).
Phase 1 adds persistent catalog, per-account cart/wishlist, owned order history,
atomic Cash on Delivery checkout and protected administrator access.
Phase 2 adds persistent profiles/addresses/preferences/card references/reviews,
full catalog editing, forward order status updates and Spark-compatible account
management. The project stays on free services with no billing upgrade.
Combined verification is deferred until implementation is complete.
Phase 3 adds reviewed Cash on Delivery checkout, delivery contact snapshots,
database-validated integer-cent totals, versioned carts, stable order retries and
in-app order notifications. See [Phase 3](docs/PHASE_3.md).
Live Firebase setup is applied; device verification is tracked separately from
local checks. See [Firebase setup](docs/FIREBASE_SETUP.md).

## Run locally

Requires Flutter with Dart 3.12.2 or newer, Android SDK (for Android), and the
Firebase configuration described in [Firebase setup](docs/FIREBASE_SETUP.md).

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

Android and iOS Firebase options are supplied. Web and desktop require their
own Firebase configuration before launching. The old hardcoded administrator
credentials have been removed: use the selected verified owner account, or a
verified account granted a bookstore admin role through protected database flags.

## Structure

- `lib/models`: serializable catalog, order and review models.
- `lib/services/auth_service.dart`: authentication and registration profiles.
- `lib/services/store_repository.dart`: Realtime Database reads and writes.
- `lib/services/store_controller.dart`: current account subscriptions and state.
- `lib/services/user_data_service.dart`: per-account profile, addresses and preferences.
- `lib/services/review_service.dart`: persistent reviews and voter-owned likes.
- `lib/services/admin_service.dart`: Spark bookstore membership management.
- `lib/services/account_policy.dart`: protected bootstrap owner identity.
- `lib/models/checkout.dart`: immutable checkout quote and delivery request.
- `lib/screens/notifications.dart`: live order inbox with read acknowledgements.
- `lib/screens`: customer flows and admin screens.
- `database.rules.json`: owner isolation and administrator permissions.
- `fixtures/catalog.json`: optional sample catalog for an empty development DB.
- `test`: controller, account isolation, order and login UI tests.
- `tools/test_database_rules.mjs`: local demo-emulator rule checks.

## Outstanding work

Theme finishing, combined verification and final report/video remain in later
phases. Checkout uses Cash on Delivery only and supports up to 20 different books.
In-app removal blocks bookstore access and clears saved customer data; Firebase
Authentication identities, registration profiles and orders remain. Permanent
Auth deletion is an owner action in Firebase Console. Phases 2/3 have not been tested;
the user requested a single combined verification after implementation.

`App-BookStore.doc` is the original requirements brief; it is not the final
implementation report. Automated tests use a local demo emulator. The
owner-authorized live setup deployed database rules, populated the catalog and
promoted the selected existing account on 13 October 2026.
