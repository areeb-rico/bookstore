import 'package:flutter/material.dart';
import '../models/book.dart';
import '../screens/user_session.dart';

const _green = Color(0xFF1E4D3B);

void showBookDetailModal(
  BuildContext context,
  Book book,
  Function(Book) onAddToCart,
  Function(String) onToggleSave,
  bool isSaved,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return _BookDetailSheet(
        book: book,
        onAddToCart: onAddToCart,
        onToggleSave: onToggleSave,
        isSaved: isSaved,
      );
    },
  );
}

class _BookDetailSheet extends StatefulWidget {
  final Book book;
  final Function(Book) onAddToCart;
  final Function(String) onToggleSave;
  final bool isSaved;

  const _BookDetailSheet({
    required this.book,
    required this.onAddToCart,
    required this.onToggleSave,
    required this.isSaved,
  });

  @override
  State<_BookDetailSheet> createState() => _BookDetailSheetState();
}

class _BookDetailSheetState extends State<_BookDetailSheet> {
  late bool isSaved;
  late List<Review> reviews;

  @override
  void initState() {
    super.initState();
    isSaved = widget.isSaved;
    reviews = ReviewStore.forBook(widget.book.id);
  }

  double get averageRating {
    if (reviews.isEmpty) return widget.book.rating;
    final sum = reviews.fold<double>(0, (s, r) => s + r.rating);
    return sum / reviews.length;
  }

  void _toggleLike(Review review) {
    setState(() {
      if (review.likedByMe) {
        review.likes--;
        review.likedByMe = false;
      } else {
        review.likes++;
        review.likedByMe = true;
      }
    });
  }

  void _showWriteReviewSheet() {
    double myRating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Write a review',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < myRating;
                      return IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          filled ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 30,
                        ),
                        onPressed: () => setSheetState(() => myRating = i + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Share what you thought about this book...',
                      filled: true,
                      fillColor: const Color(0xFFF5F5F0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final text = commentController.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Please write a few words first.'),
                            ),
                          );
                          return;
                        }

                        ReviewStore.add(
                          widget.book.id,
                          Review(
                            user: UserSession.name.isNotEmpty
                                ? UserSession.name
                                : 'You',
                            rating: myRating,
                            comment: text,
                          ),
                        );

                        Navigator.pop(ctx);
                        setState(() {
                          reviews = ReviewStore.forBook(widget.book.id);
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thanks for your review!'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Submit Review',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    book.imageUrl,
                    width: 90,
                    height: 130,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 90,
                      height: 130,
                      color: const Color(0xFFF5F5F0),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.menu_book,
                        color: Colors.black45,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By ${book.author}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          Text(
                            ' ${averageRating.toStringAsFixed(1)} ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '(${reviews.length} reviews)',
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${book.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Synopsis',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              book.description,
              style: const TextStyle(color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    widget.onToggleSave(book.id);
                    setState(() => isSaved = !isSaved);
                  },
                  icon: Icon(
                    isSaved ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  label: Text(isSaved ? 'Saved' : 'Save'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      widget.onAddToCart(book);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added "${book.title}" to cart!'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Add to Cart',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Ratings & reviews
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ratings & Reviews',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                TextButton.icon(
                  onPressed: _showWriteReviewSheet,
                  icon: const Icon(
                    Icons.rate_review_outlined,
                    size: 18,
                    color: _green,
                  ),
                  label: const Text('Write', style: TextStyle(color: _green)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No reviews yet. Be the first to review this book!',
                  style: TextStyle(color: Colors.black54),
                ),
              )
            else
              ...reviews.map(_buildReviewTile),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewTile(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: _green,
                child: Text(
                  review.user.isNotEmpty ? review.user[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                review.user,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            review.comment,
            style: const TextStyle(fontSize: 13, height: 1.3),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _toggleLike(review),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  review.likedByMe ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 15,
                  color: review.likedByMe ? _green : Colors.black45,
                ),
                const SizedBox(width: 4),
                Text(
                  'Helpful (${review.likes})',
                  style: TextStyle(
                    fontSize: 12,
                    color: review.likedByMe ? _green : Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
