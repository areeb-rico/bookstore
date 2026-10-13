import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookstore/models/book.dart';
import 'package:bookstore/models/checkout.dart';
import 'package:bookstore/screens/cart.dart';
import 'package:bookstore/screens/user_session.dart';

CheckoutQuote quote({int revision = 1}) => CheckoutQuote(
  uid: 'alice',
  cartRevision: revision,
  items: [
    CartItem(
      book: Book(
        id: 'book',
        title: 'Book',
        author: 'Author',
        price: 10,
        rating: 4,
        category: 'Fiction',
        imageUrl: '',
        description: '',
      ),
    ),
  ],
);
Order receipt(CheckoutRequest request) => Order(
  id: request.quote.orderId,
  userId: request.quote.uid,
  items: request.quote.items,
  total: request.quote.totalMinor / 100,
  shippingAddress: request.delivery.formattedAddress,
  deliveryContact: request.delivery,
  cartRevision: request.quote.cartRevision,
  cartEpoch: request.quote.cartEpoch,
  date: DateTime(2026),
);
Future<void> delivery(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Alice');
  await tester.enterText(fields.at(1), '03001234567');
  await tester.enterText(fields.at(2), 'House 12');
  await tester.enterText(fields.at(3), 'Gulshan');
  await tester.enterText(fields.at(4), 'Karachi');
  await tester.ensureVisible(find.text('Continue'));
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => UserSession.setCurrentUser({'uid': 'alice', 'name': 'Alice'}));
  tearDown(UserSession.logout);
  testWidgets(
    'confirmation waits for acknowledgement and prevents duplicate taps',
    (tester) async {
      final updates = ChangeNotifier();
      final acknowledgement = Completer<Order>();
      var calls = 0;
      CheckoutRequest? attempted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutSheet(
              quote: quote(),
              updates: updates,
              latestQuote: quote,
              onOrderPlaced: (request) {
                expect(request.delivery.name, 'Alice');
                expect(request.delivery.phone, '03001234567');
                expect(
                  request.delivery.formattedAddress,
                  'House 12, Gulshan, Karachi',
                );
                attempted = request;
                calls++;
                return acknowledgement.future;
              },
            ),
          ),
        ),
      );
      await delivery(tester);
      await tester.tap(find.text('Place Order'));
      await tester.pump();
      expect(find.text('Order Confirmed'), findsNothing);
      expect(find.text('Saving order...'), findsOneWidget);
      await tester.tap(find.text('Saving order...'));
      await tester.pump();
      expect(calls, 1);
      acknowledgement.complete(receipt(attempted!));
      await tester.pumpAndSettle();
      expect(find.text('Order Confirmed'), findsOneWidget);
      expect(find.text('Alice • 03001234567'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      updates.dispose();
    },
  );
  testWidgets(
    'failed checkout retries the same receipt with original delivery details',
    (tester) async {
      final updates = ChangeNotifier();
      final ids = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutSheet(
              quote: quote(),
              updates: updates,
              latestQuote: quote,
              onOrderPlaced: (request) async {
                ids.add(request.quote.orderId);
                if (ids.length == 1)
                  throw const CheckoutException('Connect before ordering.');
                return receipt(request);
              },
            ),
          ),
        ),
      );
      await delivery(tester);
      await tester.tap(find.text('Place Order'));
      await tester.pumpAndSettle();
      expect(find.text('Order Confirmed'), findsNothing);
      expect(find.text('Connect before ordering.'), findsOneWidget);
      await tester.tap(find.text('Retry same order'));
      await tester.pumpAndSettle();
      expect(ids, ['alice-legacy-1', 'alice-legacy-1']);
      expect(find.text('Order Confirmed'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      updates.dispose();
    },
  );
  testWidgets(
    'live cart change requires review before the first order attempt',
    (tester) async {
      final updates = ChangeNotifier();
      var current = quote();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutSheet(
              quote: current,
              updates: updates,
              latestQuote: () => current,
              onOrderPlaced: (request) async {
                calls++;
                return receipt(request);
              },
            ),
          ),
        ),
      );
      await delivery(tester);
      current = quote(revision: 2);
      updates.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.textContaining('Return to the cart'), findsOneWidget);
      await tester.tap(find.text('Place Order'));
      await tester.pump();
      expect(calls, 0);
      await tester.pumpWidget(const SizedBox());
      updates.dispose();
    },
  );
}
