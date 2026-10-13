# Saved payment methods — 13 October 2026

Checkout offers Cash on Delivery and Credit / Debit Card. Card selection displays
the signed-in customer's saved payment methods. **Create payment method** opens
the shared form used by Profile → Payment Methods. It saves a brand, four ending
digits and expiry; an acknowledged new card is selected immediately in checkout.
Expired cards cannot be selected. No full card number, CVV or payment credential
is collected or stored.

The review, confirmation, order history, notifications and administrator order
details show the chosen payment method and masked card. The interface has no
demo/test presets, simulated approvals or payment-pending labels.
**Order Confirmed** means the atomic Firebase order write was acknowledged.

There is no bank/provider gateway or real charge. Card orders retain the internal
`paymentStatus: AwaitingProcessing`; cash orders use `PayOnDelivery`. These values
are not displayed. The rules reject `Paid`, invented cards, another customer's
card and snapshot metadata that differs from the selected saved method. The
snapshot is immutable and survives later card deletion. Legacy order readers
remain compatible with earlier stored records.

The project remains on Firebase Spark. Phase 4 is not started. Widget/controller
and rules verification sources were updated for combined testing later; they
have not been executed in this task. Updated live rules and the APK build are
recorded separately.

Firebase reported the rules released successfully. Its Windows CLI then exited
with the known `UV_HANDLE_CLOSING` shutdown assertion. A separate read-only
read-back succeeded at 2026-10-13 15:55:53 UTC (20:55:53 Asia/Karachi), confirming
the deployed rules exactly match `database.rules.json`. Local file SHA-256:
`ba8ad910fb32407612233e5d36ddd39c8f23205f58e18ad21b8c79b1462283c7`.
The read-back record is in the ignored
`.firebase/setup-backups/saved-card-rules-readback.json`.
