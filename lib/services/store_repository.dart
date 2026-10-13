import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/book.dart';
import '../models/checkout.dart';
import 'auth_service.dart';

abstract class StoreRepository {
  Stream<List<Book>> watchBooks();
  Stream<Map<String, Object?>> watchCart(String uid);
  Stream<Set<String>> watchWishlist(String uid);
  Stream<List<Order>> watchOrders(String uid, {required bool admin});
  Future<void> addToCart(String uid, String bookId);
  Future<void> setQuantity(String uid, String bookId, int quantity);
  Future<void> setSaved(String uid, String bookId, bool saved);
  Future<Order> placeOrder(String uid, Order order);
  Future<void> saveBook(Book book);
  Future<void> deleteBook(String bookId);
  Future<void> setOrderStatus(String orderId, String status);
  String newOrderId();
}

class FirebaseStoreRepository implements StoreRepository {
  DatabaseReference get _root => FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: AuthService.databaseUrl,
  ).ref();

  @override
  Stream<List<Book>> watchBooks() => _root
      .child('books')
      .onValue
      .map(
        (event) => event.snapshot.children
            .map((s) => Book.fromMap(s.key!, _map(s.value)))
            .toList(),
      );

  @override
  Stream<Map<String, Object?>> watchCart(String uid) => _root
      .child('customerData/$uid/cart')
      .onValue
      .map(
        (event) => {
          for (final child in event.snapshot.children) child.key!: child.value,
        },
      );

  @override
  Stream<Set<String>> watchWishlist(String uid) => _root
      .child('customerData/$uid/wishlist')
      .onValue
      .map(
        (event) => {
          for (final child in event.snapshot.children)
            if (child.value == true) child.key!,
        },
      );

  @override
  Stream<List<Order>> watchOrders(String uid, {required bool admin}) {
    final Query query = admin
        ? _root.child('orders')
        : _root.child('orders').orderByChild('userId').equalTo(uid);
    return query.onValue.map((event) {
      final orders = event.snapshot.children
          .map((s) => Order.fromMap(s.key!, _map(s.value)))
          .toList();
      orders.sort((a, b) => b.date.compareTo(a.date));
      return orders;
    });
  }

  @override
  Future<void> addToCart(String uid, String bookId) async {
    await _changeCart(uid, bookId, (old) => old + 1);
  }

  @override
  Future<void> setQuantity(String uid, String bookId, int quantity) async {
    if (quantity < 0 || quantity > 99) {
      throw ArgumentError('Quantity must be 0–99.');
    }
    await _changeCart(uid, bookId, (_) => quantity);
  }

  Future<void> _changeCart(
    String uid,
    String bookId,
    int Function(int) change,
  ) async {
    if (bookId == '_version' || bookId == '_epoch')
      throw ArgumentError('Invalid book ID.');
    final ref = _root.child('customerData/$uid/cart');
    final initial = (await ref.get()).value;
    final newEpoch = _root.child('orders').push().key!;
    final result = await ref.runTransaction((current) {
      final value = current ?? initial;
      final next = value is Map
          ? Map<String, dynamic>.from(value)
          : <String, dynamic>{
              if (value is List)
                for (var i = 0; i < value.length; i++)
                  if (value[i] != null) '$i': value[i],
            };
      final quantity = change((next[bookId] as num?)?.toInt() ?? 0);
      if (quantity < 0 || quantity > 99) return Transaction.abort();
      if (quantity == 0) {
        next.remove(bookId);
      } else {
        next[bookId] = quantity;
      }
      next['_version'] = ((next['_version'] as num?)?.toInt() ?? 0) + 1;
      next['_epoch'] ??= newEpoch;
      return Transaction.success(next);
    }, applyLocally: false);
    if (!result.committed)
      throw StateError(
        'Cart changed or the quantity limit was reached. Try again.',
      );
  }

  @override
  Future<void> setSaved(String uid, String bookId, bool saved) => _root
      .child('customerData/$uid/wishlist/$bookId')
      .set(saved ? true : null);

  @override
  Future<Order> placeOrder(String uid, Order order) async {
    if (order.userId != uid || order.items.isEmpty) {
      throw ArgumentError('Invalid order owner/items.');
    }
    final receipt = _root.child('orders/${order.id}');
    // A stable UID/cart-version ID makes retries and two-device submissions
    // return the original receipt rather than create another order.
    Future<Order?> existing() async {
      final saved = await receipt.get();
      if (!saved.exists) return null;
      final previous = Order.fromMap(order.id, _map(saved.value));
      if (previous.userId != uid) throw StateError('Invalid order owner.');
      return previous;
    }

    final connection = await _root
        .child('.info/connected')
        .onValue
        .first
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw const CheckoutException(
            'Connect to the internet before placing your order.',
          ),
        );
    if (connection.snapshot.value != true) {
      throw const CheckoutException(
        'Connect to the internet before placing your order.',
      );
    }
    final previous = await existing();
    if (previous != null) return previous;
    try {
      // Preserve any unpurchased entries. Version validation rejects the entire
      // write if any device changed the cart since this quote was reviewed.
      await _root.update({
        'orders/${order.id}': order.toMap(),
        'customerData/$uid/cart/_version': order.cartRevision + 1,
        'customerData/$uid/cart/_epoch': order.cartEpoch,
        for (final item in order.items)
          'customerData/$uid/cart/${item.book.id}': null,
      });
      return order;
    } on FirebaseException catch (error) {
      // A concurrent identical attempt may already have committed this receipt.
      final saved = await existing();
      if (saved != null) return saved;
      if (error.code == 'permission-denied') {
        throw const CheckoutException(
          'Your cart, catalog or access changed. Return to the cart and review it before trying again.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> saveBook(Book book) =>
      _root.child('books/${book.id}').set(book.toMap());
  @override
  Future<void> deleteBook(String bookId) =>
      _root.child('books/$bookId').remove();
  @override
  Future<void> setOrderStatus(String orderId, String status) async {
    if (!Order.statuses.contains(status)) {
      throw ArgumentError('Invalid order status.');
    }
    final reference = _root.child('orders/$orderId/status');
    final initial = (await reference.get()).value;
    final result = await reference.runTransaction((current) {
      final index = Order.statuses.indexOf(
        (current ?? initial)?.toString() ?? '',
      );
      if (index < 0 ||
          index >= Order.statuses.length - 1 ||
          Order.statuses[index + 1] != status)
        return Transaction.abort();
      return Transaction.success(status);
    });
    if (!result.committed)
      throw StateError('The order status changed. Refresh and try again.');
  }

  @override
  String newOrderId() => _root.child('orders').push().key!;
}

Map<String, dynamic> _map(Object? value) =>
    Map<String, dynamic>.from(value as Map);
