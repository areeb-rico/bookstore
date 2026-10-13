import 'package:flutter_test/flutter_test.dart';
import 'package:bookstore/models/book.dart';
import 'package:bookstore/models/checkout.dart';

Book book(String id, double price) => Book(
  id: id,
  title: id,
  author: 'Author',
  price: price,
  rating: 4,
  category: 'Fiction',
  imageUrl: '',
  description: '',
);
void main() {
  test(
    'money rounds each unit to cents and SAVE10 rounds half cents upwards',
    () {
      final quote = CheckoutQuote(
        uid: 'alice',
        cartRevision: 7,
        promoCode: 'SAVE10',
        items: [CartItem(book: book('a', .05), quantity: 3)],
      );
      expect(quote.subtotalMinor, 15);
      expect(quote.totalMinor, 14);
      expect(quote.orderId, 'alice-legacy-7');
    },
  );
  test(
    'quotes preserve the reviewed quantity and distinguish restored carts',
    () {
      final source = CartItem(book: book('a', 12.99), quantity: 2);
      final quote = CheckoutQuote(
        uid: 'alice',
        cartRevision: 1,
        items: [source],
      );
      source.quantity = 9;
      expect(quote.items.single.quantity, 2);
      final restored = CheckoutQuote(
        uid: 'alice',
        cartRevision: 1,
        cartEpoch: '-O123456789012345678',
        items: [source],
      );
      expect(restored.orderId, isNot(quote.orderId));
    },
  );
  test(
    'invalid promotion, duplicate lines and more than twenty books are rejected',
    () {
      expect(
        () => CheckoutQuote(
          uid: 'alice',
          cartRevision: 1,
          promoCode: 'FREE',
          items: [CartItem(book: book('a', 10))],
        ).validate(),
        throwsStateError,
      );
      expect(
        () => CheckoutQuote(
          uid: 'alice',
          cartRevision: 1,
          items: [
            CartItem(book: book('a', 10)),
            CartItem(book: book('a', 10)),
          ],
        ).validate(),
        throwsStateError,
      );
      expect(
        () => CheckoutQuote(
          uid: 'alice',
          cartRevision: 1,
          items: [for (var i = 0; i < 21; i++) CartItem(book: book('$i', 10))],
        ).validate(),
        throwsStateError,
      );
    },
  );
  test(
    'delivery snapshot persists a usable name, normalized phone and address',
    () {
      const contact = DeliveryContact(
        name: 'Alice',
        phone: '+92 (300) 1234567',
        address: 'House 12',
        area: 'Gulshan',
        city: 'Karachi',
      );
      contact.validate();
      final decoded = DeliveryContact.fromMap(contact.toMap());
      expect(decoded.phone, '+923001234567');
      expect(decoded.name, 'Alice');
      expect(decoded.formattedAddress, 'House 12, Gulshan, Karachi');
    },
  );
}
