import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/checkout.dart';
import 'store_repository.dart';

/// Owns a single account's live data. Old account events are ignored even if
/// they arrive after subscription cancellation has started.
class StoreController extends ChangeNotifier {
  StoreController(this.repository);
  final StoreRepository repository;
  final List<Book> books = [];
  final List<CartItem> cart = [];
  final List<Order> orders = [];
  final Set<String> savedIds = {};
  final List<String> unavailableCartIds = [];
  final _orderUpdates = StreamController<Order>.broadcast();
  Stream<Order> get orderUpdates => _orderUpdates.stream;
  int get cartRevision => _quantities['_version'] ?? 0;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Map<String, int> _quantities = {};
  String _cartEpoch = 'legacy';
  String _uid = '';
  bool _admin = false;
  int _generation = 0;
  int _pending = 0;
  bool _disposed = false;
  bool checkoutPending = false;
  Timer? _loadTimeout;
  String? error;
  bool get loading => _pending > 0;
  String get uid => _uid;

  Future<void> bind(String uid, {required bool admin}) async {
    final generation = ++_generation;
    _uid = uid;
    _admin = admin;
    checkoutPending = false;
    final previous = List<StreamSubscription<dynamic>>.from(_subscriptions);
    _subscriptions.clear();
    books.clear();
    cart.clear();
    orders.clear();
    savedIds.clear();
    unavailableCartIds.clear();
    _quantities = {};
    _cartEpoch = 'legacy';
    error = null;
    _loadTimeout?.cancel();
    _pending = uid.isEmpty ? 0 : 4;
    _notify();
    await Future.wait(previous.map((s) => s.cancel()));
    if (_disposed || generation != _generation || uid.isEmpty) return;
    _loadTimeout = Timer(const Duration(seconds: 15), () {
      if (_disposed || generation != _generation || !loading) return;
      error = 'Loading timed out. Check your connection and try again.';
      _pending = 0;
      _notify();
    });
    _listen(repository.watchBooks(), generation, (value) {
      books
        ..clear()
        ..addAll(value);
      _rebuildCart();
    });
    _listen(repository.watchCart(uid), generation, (value) {
      _cartEpoch = value['_epoch'] as String? ?? 'legacy';
      _quantities = {
        for (final entry in value.entries)
          if (entry.value is num) entry.key: (entry.value as num).toInt(),
      };
      _rebuildCart();
    });
    _listen(repository.watchWishlist(uid), generation, (value) {
      savedIds
        ..clear()
        ..addAll(value);
    });
    var ordersReady = false;
    _listen(repository.watchOrders(uid, admin: admin), generation, (value) {
      if (ordersReady) {
        final previous = {for (final order in orders) order.id: order.status};
        for (final order in value) {
          if (order.userId == uid &&
              previous.containsKey(order.id) &&
              previous[order.id] != order.status) {
            _orderUpdates.add(order);
          }
        }
      }
      ordersReady = true;
      orders
        ..clear()
        ..addAll(value);
    });
  }

  void _listen<T>(Stream<T> stream, int generation, void Function(T) apply) {
    var first = true;
    void ready() {
      if (first) {
        first = false;
        if (_pending > 0) _pending--;
      }
    }

    _subscriptions.add(
      stream.listen(
        (value) {
          if (_disposed || generation != _generation) return;
          ready();
          apply(value);
          _notify();
        },
        onError: (Object failure) {
          if (_disposed || generation != _generation) return;
          ready();
          error =
              'Could not load store data. Check your connection and try again.';
          _notify();
        },
      ),
    );
  }

  void _rebuildCart() {
    final ids = books.map((b) => b.id).toSet();
    unavailableCartIds
      ..clear()
      ..addAll(
        _quantities.keys.where((id) => id != '_version' && !ids.contains(id)),
      );
    cart
      ..clear()
      ..addAll(
        books
            .where((b) => (_quantities[b.id] ?? 0) > 0)
            .map((b) => CartItem(book: b, quantity: _quantities[b.id]!)),
      );
  }

  void _requireCustomer() {
    if (_uid.isEmpty || _admin) {
      throw StateError('Please sign in as a customer.');
    }
    if (loading || error != null) {
      throw StateError('Store data is not ready. Retry loading first.');
    }
    if (checkoutPending) {
      throw StateError('An order is being saved. Please wait.');
    }
  }

  Future<void> addToCart(Book book) {
    _requireCustomer();
    if (!books.any((b) => b.id == book.id)) {
      throw StateError('This book is no longer available.');
    }
    return repository.addToCart(_uid, book.id);
  }

  Future<void> setQuantity(Book book, int quantity) {
    _requireCustomer();
    return repository.setQuantity(_uid, book.id, quantity);
  }

  Future<void> toggleSaved(String bookId) {
    _requireCustomer();
    return repository.setSaved(_uid, bookId, !savedIds.contains(bookId));
  }

  CheckoutQuote quote({String promoCode = ''}) => CheckoutQuote(
    uid: _uid,
    cartRevision: cartRevision,
    cartEpoch: _cartEpoch,
    items: cart,
    promoCode: promoCode,
  );

  Future<void> removeUnavailableItems() async {
    _requireCustomer();
    final owner = _uid;
    final generation = _generation;
    for (final id in List<String>.from(unavailableCartIds)) {
      if (_disposed || generation != _generation) {
        throw const CheckoutException('Account changed. Open the cart again.');
      }
      await repository.setQuantity(owner, id, 0);
    }
  }

  Future<Order> placeOrder(CheckoutRequest request) async {
    _requireCustomer();
    final reviewed = request.quote;
    if (reviewed.uid != _uid)
      throw const CheckoutException('Account changed. Open checkout again.');
    reviewed.validate();
    request.delivery.validate();
    checkoutPending = true;
    final generation = _generation;
    final owner = _uid;
    _notify();
    try {
      // Firebase rules validate the quote against current catalog/cart data.
      // The repository checks an existing receipt first so retries still work
      // when the first attempt cleared the cart but its acknowledgement was lost.
      return await repository.placeOrder(
        owner,
        Order(
          id: reviewed.orderId,
          userId: owner,
          items: reviewed.items,
          total: reviewed.totalMinor / 100,
          shippingAddress: request.delivery.formattedAddress,
          deliveryContact: request.delivery,
          promoCode: reviewed.promoCode,
          cartRevision: reviewed.cartRevision,
          cartEpoch: reviewed.cartEpoch,
          paymentMethod: 'Cash',
          date: DateTime.now(),
        ),
      );
    } finally {
      if (generation == _generation) {
        checkoutPending = false;
        _notify();
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _loadTimeout?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    unawaited(_orderUpdates.close());
    super.dispose();
  }
}
