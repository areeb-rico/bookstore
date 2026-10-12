import 'package:flutter/material.dart';
import '../models/book.dart';
import '../widgets/book_detail_modal.dart';

class BrowserScreen extends StatefulWidget {
  final List<Book> allBooks;
  final List<CartItem> cartItems;
  final Set<String> savedBookIds;
  final Function(Book) onAddToCart;
  final Function(String) onToggleSave;

  const BrowserScreen({
    super.key,
    required this.allBooks,
    required this.cartItems,
    required this.savedBookIds,
    required this.onAddToCart,
    required this.onToggleSave,
  });

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  String selectedCategory = 'All';
  String selectedAuthor = 'All';
  String searchQuery = '';
  String sortBy = 'Popularity';

  final List<String> sortOptions = [
    'Popularity',
    'Price: Low to High',
    'Price: High to Low',
    'Newest',
  ];

  List<Book> _applySort(List<Book> books) {
    switch (sortBy) {
      case 'Price: Low to High':
        books.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        books.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Newest':
        books.sort((a, b) => int.parse(b.id).compareTo(int.parse(a.id)));
        break;
      case 'Popularity':
      default:
        books.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return books;
  }

  @override
  Widget build(BuildContext context) {
    final String query = searchQuery.toLowerCase();

    final List<String> authors = [
      'All',
      ...{for (final b in widget.allBooks) b.author},
    ];

    final filtered = _applySort(
      widget.allBooks.where((b) {
        final matchesCategory =
            selectedCategory == 'All' || b.category == selectedCategory;

        final matchesAuthor =
            selectedAuthor == 'All' || b.author == selectedAuthor;

        final matchesSearch =
            b.title.toLowerCase().contains(query) ||
            b.author.toLowerCase().contains(query) ||
            b.category.toLowerCase().contains(query);

        return matchesCategory && matchesAuthor && matchesSearch;
      }).toList(),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F0),
        elevation: 0,
        title: const Text(
          'Browse Library',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.black,
              ),
              onPressed: () => Navigator.pushNamed(context, '/cart'),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                });
              },

              decoration: InputDecoration(
                hintText: 'Search titles, authors, genres',

                prefixIcon: const Icon(Icons.search, color: Colors.black45),

                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black45),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                    : null,

                filled: true,
                fillColor: Colors.white,

                contentPadding: const EdgeInsets.symmetric(vertical: 12),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Fiction', 'Sci-Fi', 'Mystery', 'History']
                    .map((category) {
                      final isSelected = selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(category),
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF1E4D3B),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (_) =>
                              setState(() => selectedCategory = category),
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: authors.map((author) {
                  final isSelected = selectedAuthor == author;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(author),
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF1E4D3B),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (_) =>
                          setState(() => selectedAuthor = author),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${filtered.length} books',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const Spacer(),
                const Icon(Icons.sort, size: 18, color: Colors.black54),
                const SizedBox(width: 6),
                DropdownButton<String>(
                  value: sortBy,
                  underline: const SizedBox(),
                  isDense: true,
                  borderRadius: BorderRadius.circular(10),
                  style: const TextStyle(
                    color: Color(0xFF1E4D3B),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  items: sortOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => sortBy = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 16,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final book = filtered[index];
                  final isSaved = widget.savedBookIds.contains(book.id);
                  return GestureDetector(
                    onTap: () => showBookDetailModal(
                      context,
                      book,
                      widget.onAddToCart,
                      widget.onToggleSave,
                      isSaved,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  book.imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        width: double.infinity,
                                        height: double.infinity,
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
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: () => widget.onToggleSave(book.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isSaved
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isSaved
                                          ? Colors.red
                                          : Colors.black54,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${book.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF1E4D3B),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                Text(
                                  ' ${book.rating}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
