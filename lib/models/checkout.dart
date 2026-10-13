import 'dart:convert';
import 'book.dart';

/// An immutable review of one account's cart and catalog at checkout opening.
class CheckoutQuote {
  CheckoutQuote({
    required this.uid,
    required this.cartRevision,
    this.cartEpoch = 'legacy',
    required List<CartItem> items,
    this.promoCode = '',
  }) : items = List.unmodifiable(
         items.map(
           (item) => CartItem(book: item.book, quantity: item.quantity),
         ),
       );
  final String uid;
  final int cartRevision;
  final String cartEpoch;
  final List<CartItem> items;
  final String promoCode;
  int get subtotalMinor =>
      items.fold(0, (sum, item) => sum + item.book.priceMinor * item.quantity);
  int get totalMinor =>
      promoCode == 'SAVE10' ? (subtotalMinor * 90 + 50) ~/ 100 : subtotalMinor;
  String get orderId => '$uid-$cartEpoch-$cartRevision';
  String get fingerprint => jsonEncode({
    'uid': uid,
    'revision': cartRevision,
    'epoch': cartEpoch,
    'promo': promoCode,
    'items': [
      for (final item in items)
        {
          'id': item.book.id,
          'quantity': item.quantity,
          'book': item.book.toMap(),
        },
    ],
  });
  void validate() {
    if (uid.isEmpty ||
        cartRevision < 0 ||
        (cartEpoch != 'legacy' &&
            !RegExp(r'^[A-Za-z0-9_-]{20}$').hasMatch(cartEpoch)) ||
        items.isEmpty ||
        items.length > Order.maxItems ||
        items.map((i) => i.book.id).toSet().length != items.length ||
        items.any(
          (i) =>
              i.quantity < 1 ||
              i.quantity > 99 ||
              !i.book.price.isFinite ||
              i.book.price < 0 ||
              i.book.price > 100000,
        ) ||
        !['', 'SAVE10'].contains(promoCode)) {
      throw StateError(
        'Review your cart. Each order supports up to ${Order.maxItems} different books and 1–99 copies per book.',
      );
    }
  }
}

class CheckoutRequest {
  const CheckoutRequest({required this.quote, required this.delivery});
  final CheckoutQuote quote;
  final DeliveryContact delivery;
}

class CheckoutException implements Exception {
  const CheckoutException(this.message);
  final String message;
  @override
  String toString() => message;
}
