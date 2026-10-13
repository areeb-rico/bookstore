class Book {
  final String id;
  final String title;
  final String author;
  final double price;
  final double rating;
  final String category;
  final String imageUrl;
  final String description;
  final DateTime releaseDate;
  int get priceMinor => (price * 100).round();

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.price,
    required this.rating,
    required this.category,
    required this.imageUrl,
    required this.description,
    DateTime? releaseDate,
  }) : releaseDate = releaseDate ?? DateTime(1970);

  Map<String, dynamic> toMap() => {
    'title': title,
    'author': author,
    'price': price,
    'rating': rating,
    'category': category,
    'imageUrl': imageUrl,
    'description': description,
    'releaseDate': releaseDate.toIso8601String(),
  };

  factory Book.fromMap(String id, Map<String, dynamic> data) => Book(
    id: id,
    title: data['title'] as String,
    author: data['author'] as String,
    price: (data['price'] as num).toDouble(),
    rating: (data['rating'] as num?)?.toDouble() ?? 0,
    category: data['category'] as String,
    imageUrl: data['imageUrl'] as String,
    description: data['description'] as String? ?? '',
    releaseDate: DateTime.tryParse(data['releaseDate'] as String? ?? ''),
  );
}

class CartItem {
  final Book book;
  int quantity;

  CartItem({required this.book, this.quantity = 1});
}

class Order {
  static const maxItems = 20;
  static const statuses = [
    'Ordered',
    'Processing',
    'Shipped',
    'Out for delivery',
    'Delivered',
  ];
  final String id;
  final String userId;
  final List<CartItem> items;
  final double total;
  final String shippingAddress;
  String status;
  final DateTime date;
  final String paymentMethod;
  final DemoPayment? demoPayment;
  final SavedPaymentMethod? cardPayment;
  final String paymentStatus;
  String get paymentLabel => switch (paymentMethod) {
    'Cash' => 'Cash on Delivery',
    'Card' || 'CardDemo' => 'Credit / Debit Card',
    _ => paymentMethod,
  };
  final DeliveryContact? deliveryContact;
  final String promoCode;
  final int cartRevision;
  final String cartEpoch;
  int get totalMinor => (total * 100).round();
  int get subtotalMinor =>
      items.fold(0, (sum, item) => sum + item.book.priceMinor * item.quantity);

  String? get cardLabel =>
      cardPayment?.label ??
      (demoPayment == null
          ? null
          : '${demoPayment!.brand} •••• ${demoPayment!.last4}');

  Order({
    required this.id,
    this.userId = '',
    required this.items,
    required this.total,
    required this.shippingAddress,
    this.status = 'Ordered',
    required this.date,
    this.paymentMethod = 'Cash',
    this.demoPayment,
    this.cardPayment,
    this.paymentStatus = 'PayOnDelivery',
    this.deliveryContact,
    this.promoCode = '',
    this.cartRevision = 0,
    this.cartEpoch = 'legacy',
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'total': total,
    'shippingAddress': shippingAddress,
    'status': status,
    'date': date.toIso8601String(),
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    if (cardPayment != null) 'cardPayment': cardPayment!.toMap(),
    if (demoPayment != null) 'demoPayment': demoPayment!.toMap(),
    'schemaVersion': 2,
    'subtotalMinor': subtotalMinor,
    'totalMinor': totalMinor,
    'promoCode': promoCode,
    'cartRevision': cartRevision,
    'cartEpoch': cartEpoch,
    if (deliveryContact != null) 'deliveryContact': deliveryContact!.toMap(),
    'items': {
      for (var i = 0; i < items.length; i++)
        '$i': {
          'bookId': items[i].book.id,
          'book': items[i].book.toMap(),
          'quantity': items[i].quantity,
          'unitPriceMinor': items[i].book.priceMinor,
          'lineTotalMinor': items[i].book.priceMinor * items[i].quantity,
        },
    },
  };

  factory Order.fromMap(String id, Map<String, dynamic> data) {
    final raw = data['items'];
    // Realtime Database may return contiguous numeric keys as a List.
    final values = raw is List
        ? raw.whereType<Map>()
        : (raw as Map).values.cast<Map>();
    return Order(
      id: id,
      userId: data['userId'] as String,
      items: values
          .map(
            (item) => CartItem(
              book: Book.fromMap(
                item['bookId'] as String,
                Map<String, dynamic>.from(item['book'] as Map),
              ),
              quantity: (item['quantity'] as num).toInt(),
            ),
          )
          .toList(),
      total: (data['total'] as num).toDouble(),
      shippingAddress: data['shippingAddress'] as String,
      status: data['status'] as String,
      date: DateTime.parse(data['date'] as String),
      paymentMethod: data['paymentMethod'] as String? ?? 'Cash',
      paymentStatus:
          data['paymentStatus'] as String? ??
          (data['paymentMethod'] == 'Cash' ? 'PayOnDelivery' : 'NotCharged'),
      cardPayment: data['cardPayment'] is Map
          ? SavedPaymentMethod.fromMap(
              Map<String, dynamic>.from(data['cardPayment'] as Map),
            )
          : null,
      demoPayment: data['demoPayment'] is Map
          ? DemoPayment.fromMap(
              Map<String, dynamic>.from(data['demoPayment'] as Map),
            )
          : null,
      deliveryContact: data['deliveryContact'] is Map
          ? DeliveryContact.fromMap(
              Map<String, dynamic>.from(data['deliveryContact'] as Map),
            )
          : null,
      promoCode: data['promoCode'] as String? ?? '',
      cartRevision: (data['cartRevision'] as num?)?.toInt() ?? 0,
      cartEpoch: data['cartEpoch'] as String? ?? 'legacy',
    );
  }
}

/// A local simulation receipt. It is never evidence of a bank/provider charge.
class DemoPayment {
  const DemoPayment({
    required this.reference,
    required this.amountMinor,
    this.mode = 'demo',
    this.status = 'approved',
    this.brand = 'Visa',
    this.last4 = '4242',
  });
  final String mode, status, reference, brand, last4;
  final int amountMinor;
  bool matches(String orderId, int expectedAmount) =>
      mode == 'demo' &&
      status == 'approved' &&
      reference == 'DEMO-$orderId' &&
      brand == 'Visa' &&
      last4 == '4242' &&
      amountMinor == expectedAmount;
  Map<String, dynamic> toMap() => {
    'mode': mode,
    'status': status,
    'reference': reference,
    'brand': brand,
    'last4': last4,
    'amountMinor': amountMinor,
  };
  factory DemoPayment.fromMap(Map<String, dynamic> data) => DemoPayment(
    mode: data['mode'] as String,
    status: data['status'] as String,
    reference: data['reference'] as String,
    brand: data['brand'] as String,
    last4: data['last4'] as String,
    amountMinor: (data['amountMinor'] as num).toInt(),
  );
}

class SavedPaymentMethod {
  const SavedPaymentMethod({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expiry,
  });
  final String id, brand, last4, expiry;
  factory SavedPaymentMethod.fromMap(Map<String, dynamic> data) =>
      SavedPaymentMethod(
        id: data['id'] as String,
        brand: data['brand'] as String,
        last4: data['last4'] as String,
        expiry: data['expiry'] as String,
      );
  Map<String, String> toMap() => {
    'id': id,
    'brand': brand,
    'last4': last4,
    'expiry': expiry,
  };
  String get label => '$brand •••• $last4';
  void validate() {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(id) ||
        !['Visa', 'Mastercard', 'American Express'].contains(brand) ||
        !RegExp(r'^\d{4}$').hasMatch(last4) ||
        !RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(expiry)) {
      throw StateError('Select a valid saved payment method.');
    }
    final parts = expiry.split('/');
    if (!DateTime(
      2000 + int.parse(parts[1]),
      int.parse(parts[0]) + 1,
    ).isAfter(DateTime.now())) {
      throw StateError('This card has expired. Create another payment method.');
    }
  }
}

class DeliveryContact {
  const DeliveryContact({
    required this.name,
    required this.phone,
    required this.address,
    required this.area,
    required this.city,
  });
  final String name, phone, address, area, city;
  String get formattedAddress => '$address, $area, $city';
  Map<String, String> toMap() => {
    'name': name,
    'phone': phone.replaceAll(RegExp(r'[ ()-]'), ''),
    'address': address,
    'area': area,
    'city': city,
  };
  factory DeliveryContact.fromMap(Map<String, dynamic> data) => DeliveryContact(
    name: data['name'] as String,
    phone: data['phone'] as String,
    address: data['address'] as String,
    area: data['area'] as String,
    city: data['city'] as String,
  );
  void validate() {
    if (name.trim().length < 2 ||
        name.length > 120 ||
        !RegExp(r'^\+?[0-9 ()-]{10,30}$').hasMatch(phone) ||
        phone.replaceAll(RegExp(r'\D'), '').length < 10 ||
        phone.replaceAll(RegExp(r'\D'), '').length > 15 ||
        address.trim().isEmpty ||
        address.length > 300 ||
        area.trim().isEmpty ||
        area.length > 120 ||
        city.trim().isEmpty ||
        city.length > 120) {
      throw StateError(
        'Enter a valid delivery name, phone and complete address.',
      );
    }
  }
}

class Review {
  final String id;
  final String userId;
  final DateTime date;
  final String user;
  final double rating;
  final String comment;
  int likes;
  bool likedByMe;

  Review({
    this.id = '',
    this.userId = '',
    DateTime? date,
    required this.user,
    required this.rating,
    required this.comment,
    this.likes = 0,
    this.likedByMe = false,
  }) : date = date ?? DateTime(1970);
}

// Legacy helper retained for existing Phase 1 tests; production reviews use ReviewService.
class ReviewStore {
  static final Map<String, List<Review>> _reviews = {};
  static void clear() => _reviews.clear();
  static List<Review> forBook(String id) => _reviews.putIfAbsent(id, () => []);
  static void add(String id, Review review) => forBook(id).insert(0, review);
}
