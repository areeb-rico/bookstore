import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookstore/models/book.dart';
import 'package:bookstore/models/checkout.dart';
import 'package:bookstore/services/store_controller.dart';
import 'package:bookstore/services/store_repository.dart';
import 'package:bookstore/screens/user_session.dart';

Book book({String id = 'book-uuid', double price = 10}) => Book(
  id: id,
  title: 'A',
  author: 'Author',
  price: price,
  rating: 4,
  category: 'Fiction',
  imageUrl: '',
  description: 'Description',
  releaseDate: DateTime(2026, 10, 1),
);

class FakeRepository implements StoreRepository {
  final catalog = StreamController<List<Book>>.broadcast();
  final carts = <String, StreamController<Map<String, int>>>{};
  final wishlists = <String, StreamController<Set<String>>>{};
  final histories = <String, StreamController<List<Order>>>{};
  final cartWrites = <String>[];
  final wishlistWrites = <String>[];
  final placed = <Order>[];
  bool failOrder = false;
  Completer<void>? orderWait;
  @override
  Stream<List<Book>> watchBooks() => catalog.stream;
  @override
  Stream<Map<String, int>> watchCart(String uid) =>
      (carts[uid] ??= StreamController<Map<String, int>>.broadcast()).stream;
  @override
  Stream<Set<String>> watchWishlist(String uid) =>
      (wishlists[uid] ??= StreamController<Set<String>>.broadcast()).stream;
  @override
  Stream<List<Order>> watchOrders(String uid, {required bool admin}) =>
      (histories[uid] ??= StreamController<List<Order>>.broadcast()).stream;
  @override
  Future<void> addToCart(String uid, String id) async {
    cartWrites.add('$uid/$id');
  }

  @override
  Future<void> setQuantity(String uid, String id, int quantity) async {
    cartWrites.add('$uid/$id/$quantity');
  }

  @override
  Future<void> setSaved(String uid, String id, bool saved) async {
    wishlistWrites.add('$uid/$id/$saved');
  }

  @override
  Future<Order> placeOrder(String uid, Order order) async {
    if (orderWait != null) await orderWait!.future;
    if (failOrder) throw StateError('Write denied');
    placed.add(order);
    carts[uid]!.add({'_version': order.cartRevision + 1});
    histories[uid]!.add([order]);
    return order;
  }

  @override
  String newOrderId() => 'order-${placed.length}';
  @override
  Future<void> saveBook(Book value) async {}
  @override
  Future<void> deleteBook(String id) async {}
  @override
  Future<void> setOrderStatus(String id, String status) async {}

  Future<void> emit(String uid, {int quantity = 1}) async {
    catalog.add([book()]);
    carts[uid]!.add({'book-uuid': quantity, '_version': 1});
    wishlists[uid]!.add({'book-uuid'});
    histories[uid]!.add([]);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> close() async {
    await catalog.close();
    for (final stream in [
      ...carts.values,
      ...wishlists.values,
      ...histories.values,
    ]) {
      await stream.close();
    }
  }
}

CheckoutRequest request(StoreController store, {String promoCode = ''}) =>
    CheckoutRequest(
      quote: store.quote(promoCode: promoCode),
      delivery: const DeliveryContact(
        name: 'Alice',
        phone: '03001234567',
        address: 'House 12',
        area: 'Gulshan',
        city: 'Karachi',
      ),
    );

void main() {
  late FakeRepository repo;
  late StoreController store;
  setUp(() {
    repo = FakeRepository();
    store = StoreController(repo);
  });
  tearDown(() async {
    store.dispose();
    await repo.close();
    UserSession.logout();
  });

  test('cart and wishlist writes always carry the current owner UID', () async {
    await store.bind('alice', admin: false);
    await repo.emit('alice');
    await store.addToCart(book());
    await store.toggleSaved('book-uuid');
    expect(repo.cartWrites, ['alice/book-uuid']);
    expect(repo.wishlistWrites, ['alice/book-uuid/false']);
    expect(store.cart.single.quantity, 1);
  });

  test(
    'account switch clears all old data immediately and ignores old events',
    () async {
      await store.bind('alice', admin: false);
      await repo.emit('alice', quantity: 3);
      final binding = store.bind('bob', admin: false);
      expect(store.cart, isEmpty);
      expect(store.orders, isEmpty);
      expect(store.savedIds, isEmpty);
      await binding;
      repo.carts['alice']!.add({'book-uuid': 99});
      await repo.emit('bob', quantity: 2);
      expect(store.uid, 'bob');
      expect(store.cart.single.quantity, 2);
      await store.setQuantity(book(), 4);
      expect(repo.cartWrites.single, 'bob/book-uuid/4');
    },
  );

  test('logout removes customer data and prevents further writes', () async {
    await store.bind('alice', admin: false);
    await repo.emit('alice');
    await store.bind('', admin: false);
    expect(store.books, isEmpty);
    expect(store.cart, isEmpty);
    expect(store.savedIds, isEmpty);
    expect(() => store.addToCart(book()), throwsStateError);
    expect(repo.cartWrites, isEmpty);
  });

  test('failed checkout retains cart and allows a retry', () async {
    await store.bind('alice', admin: false);
    await repo.emit('alice', quantity: 2);
    repo.failOrder = true;
    await expectLater(store.placeOrder(request(store)), throwsStateError);
    expect(store.cart.single.quantity, 2);
    expect(store.checkoutPending, isFalse);
    expect(repo.placed, isEmpty);
    repo.failOrder = false;
    await store.placeOrder(request(store, promoCode: 'SAVE10'));
    await Future<void>.delayed(Duration.zero);
    expect(repo.placed.single.userId, 'alice');
    expect(store.cart, isEmpty);
    expect(repo.placed.single.total, 18);
  });

  test('pending checkout blocks duplicate orders and cart edits', () async {
    await store.bind('alice', admin: false);
    await repo.emit('alice');
    repo.orderWait = Completer<void>();
    final pending = store.placeOrder(request(store));
    await expectLater(store.placeOrder(request(store)), throwsStateError);
    expect(() => store.addToCart(book()), throwsStateError);
    repo.orderWait!.complete();
    await pending;
    expect(repo.placed, hasLength(1));
  });

  test(
    'checkout rejects invalid promotions, wrong owners and admin customer writes',
    () async {
      await store.bind('alice', admin: false);
      await repo.emit('alice');
      await expectLater(
        store.placeOrder(request(store, promoCode: 'UNAUTHORIZED')),
        throwsStateError,
      );
      await expectLater(
        store.placeOrder(
          CheckoutRequest(
            quote: CheckoutQuote(
              uid: 'bob',
              cartRevision: 1,
              items: store.cart,
            ),
            delivery: request(store).delivery,
          ),
        ),
        throwsA(isA<CheckoutException>()),
      );
      await store.bind('admin', admin: true);
      await repo.emit('admin');
      expect(() => store.addToCart(book()), throwsStateError);
      expect(repo.placed, isEmpty);
    },
  );

  test('stream failure is shown and account rebinding can recover', () async {
    await store.bind('alice', admin: false);
    await repo.emit('alice');
    repo.carts['alice']!.addError(StateError('Permission denied'));
    await Future<void>.delayed(Duration.zero);
    expect(store.error, isNotNull);
    expect(() => store.addToCart(book()), throwsStateError);
    await store.bind('alice', admin: false);
    await repo.emit('alice');
    expect(store.error, isNull);
    expect(store.loading, isFalse);
  });

  test(
    'order alerts ignore initial history, new orders and other accounts',
    () async {
      await store.bind('alice', admin: false);
      await repo.emit('alice');
      final alerts = <Order>[];
      final subscription = store.orderUpdates.listen(alerts.add);
      Order history(String status, {String uid = 'alice'}) => Order(
        id: 'history',
        userId: uid,
        items: [CartItem(book: book())],
        total: 10,
        shippingAddress: 'House 12',
        status: status,
        date: DateTime(2026),
      );
      repo.histories['alice']!.add([history('Ordered')]);
      await Future<void>.delayed(Duration.zero);
      expect(alerts, isEmpty);
      repo.histories['alice']!.add([history('Processing')]);
      await Future<void>.delayed(Duration.zero);
      expect(alerts.map((o) => o.status), ['Processing']);
      await store.bind('bob', admin: false);
      await repo.emit('bob');
      repo.histories['alice']!.add([history('Shipped')]);
      await Future<void>.delayed(Duration.zero);
      expect(alerts, hasLength(1));
      await subscription.cancel();
    },
  );

  test('order serialization preserves book snapshot, owner and quantities', () {
    final original = Order(
      id: 'ord',
      userId: 'alice',
      items: [CartItem(book: book(), quantity: 2)],
      total: 20,
      shippingAddress: 'Address',
      date: DateTime(2026),
    );
    final decoded = Order.fromMap(original.id, original.toMap());
    expect(decoded.userId, 'alice');
    expect(decoded.items.single.quantity, 2);
    expect(decoded.items.single.book.releaseDate, DateTime(2026, 10, 1));
    expect(decoded.items.single.book.title, 'A');
    final numericArray = original.toMap()
      ..['items'] = (original.toMap()['items'] as Map).values.toList();
    expect(Order.fromMap('ord', numericArray).items.single.quantity, 2);
  });

  test(
    'new account and logout clear addresses, reviews and dark preference',
    () {
      UserSession.setCurrentUser({'uid': 'alice', 'name': 'Alice'});
      UserSession.shippingAddresses.add({'address': 'Private'});
      ReviewStore.add(
        'book',
        Review(user: 'Alice', rating: 5, comment: 'Private'),
      );
      UserSession.setDarkMode(true);
      UserSession.setCurrentUser({'uid': 'bob', 'name': 'Bob'});
      expect(UserSession.shippingAddresses, isEmpty);
      expect(ReviewStore.forBook('book'), isEmpty);
      expect(UserSession.darkMode.value, isFalse);
      UserSession.logout();
      expect(UserSession.uid, isEmpty);
      expect(UserSession.isLoggedIn, isFalse);
    },
  );
}
