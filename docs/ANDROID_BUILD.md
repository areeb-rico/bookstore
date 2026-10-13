# Android release APK for testing — 13 October 2026

Latest build succeeded with
`flutter build apk --release --no-pub --build-name=1.0.3 --build-number=4`
(exit code 0, 410.4 seconds). This APK includes saved-card selection and the
shared **Create payment method** form in checkout/profile. It removes the earlier
simulation controls and visible demo/test/payment-pending labels.
APK: `build/app/outputs/flutter-apk/app-release.apk`.

- Package: `com.example.bookstore`.
- Version: `1.0.3`, version code `4`.
- Size: 56,112,483 bytes (approximately 53.5 MiB).
- Minimum Android SDK: 24; target/compile SDK: 36.
- Native architectures: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- `aapt dump badging` confirms package/version/architectures and does not report
  the application as debuggable.
- `apksigner verify --verbose --print-certs` passed (exit code 0), using APK
  Signature Scheme v2. The existing Android Debug certificate signs this release
  build for testing; a production signing key has not been configured.
- APK SHA-256:
  `9d562b1b57a28e64bd7ff60873c344c6999cbf2490b53ba21e4d18afd547f99a`.

Earlier builds were versions 1.0.0–1.0.2 (codes 1–3). The current output replaces
them with version 1.0.3 (code 4), generated at 21:00:06 Asia/Karachi.
Customers select Cash on Delivery or Credit / Debit Card and a saved card.
**Order Confirmed** follows the database acknowledgement, without claiming a
bank charge. No bank/provider gateway is connected.
See [payment methods](PAYMENT_METHODS.md). Widget/controller/rules verification
sources were updated, but not executed.

The Gradle 9.1.0 distribution download stalled with an empty partial file. The
wrapper was updated to the already installed Gradle 9.3.1, after which the build
succeeded. AGP 9.0.1 specifies Gradle 9.1.0 as its minimum;
see [Android compatibility notes](https://developer.android.com/build/releases/agp-9-0-0-release-notes).
Flutter 3.47.5 / Dart 3.13.4 and JDK 17 were used. Non-fatal plugin Kotlin and
Java deprecation/unchecked-operation warnings were reported.

No automated tests, device installation or app behavior checks were run here.
Those remain queued for combined verification. Phase 4 was not started.
The APK is excluded from Git through `/build/`. Source and documentation are
committed separately to the owner's BookStore repository; no APK is included.
