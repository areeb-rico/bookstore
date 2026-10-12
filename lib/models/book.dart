class Book {
  final String id;
  final String title;
  final String author;
  final double price;
  final double rating;
  final String category;
  final String imageUrl;
  final String description;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.price,
    required this.rating,
    required this.category,
    required this.imageUrl,
    required this.description,
  });
}

class CartItem {
  final Book book;
  int quantity;

  CartItem({required this.book, this.quantity = 1});
}

class Order {
  final String id;
  final List<CartItem> items;
  final double total;
  final String shippingAddress;
  String status;
  final DateTime date;

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.shippingAddress,
    this.status = 'Ordered',
    required this.date,
  });
}

class Review {
  final String user;
  final double rating;
  final String comment;
  int likes;
  bool likedByMe;

  Review({
    required this.user,
    required this.rating,
    required this.comment,
    this.likes = 0,
    this.likedByMe = false,
  });
}

// Simple in-memory reviews, kept per book id so they survive while the app runs.
class ReviewStore {
  static final Map<String, List<Review>> _reviews = {
    '1': [
      Review(
        user: 'Hira',
        rating: 5,
        comment: 'Could not put it down, the twist got me completely.',
        likes: 12,
      ),
      Review(
        user: 'Daniyal',
        rating: 4,
        comment: 'Slow start but a brilliant ending.',
        likes: 5,
      ),
    ],
    '2': [
      Review(
        user: 'Sana',
        rating: 5,
        comment: 'Best sci-fi I have read in years. Rocky is the best.',
        likes: 20,
      ),
    ],
    '3': [
      Review(
        user: 'Ahmed',
        rating: 5,
        comment: 'Actually changed how I build my daily routine.',
        likes: 31,
      ),
      Review(
        user: 'Mehwish',
        rating: 4,
        comment: 'Practical and easy to follow.',
        likes: 7,
      ),
    ],
  };

  static List<Review> forBook(String bookId) {
    return _reviews.putIfAbsent(bookId, () => []);
  }

  static void add(String bookId, Review review) {
    forBook(bookId).insert(0, review);
  }
}
