import 'package:flutter/material.dart';
import '../../models/book.dart';

class ManageBooksScreen extends StatefulWidget {
  final List<Book> allBooks;

  const ManageBooksScreen({super.key, required this.allBooks});

  @override
  State<ManageBooksScreen> createState() => _ManageBooksScreenState();
}

class _ManageBooksScreenState extends State<ManageBooksScreen> {
  final _searchCtl = TextEditingController();
  String _q = '';

  List<Book> get _vis {
    if (_q.isEmpty) return widget.allBooks;
    var needle = _q.toLowerCase();
    var out = <Book>[];
    var i = 0;
    while (i < widget.allBooks.length) {
      var b = widget.allBooks[i];
      var t = b.title.toLowerCase();
      var a = b.author.toLowerCase();
      var g = b.category.toLowerCase();
      if (t.contains(needle) || a.contains(needle) || g.contains(needle))
        out.add(b);
      i++;
    }
    return out;
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  void _openForm({Book? existing, int? idx}) {
    var t = TextEditingController(text: existing?.title ?? '');
    var a = TextEditingController(text: existing?.author ?? '');
    var p = TextEditingController(
      text: existing == null ? '' : existing.price.toStringAsFixed(2),
    );
    var g = TextEditingController(text: existing?.category ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              existing == null ? 'Add book' : 'Edit book',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            _tf(t, 'Title'),
            const SizedBox(height: 10),
            _tf(a, 'Author'),
            const SizedBox(height: 10),
            _tf(p, 'Price (e.g. 12.99)', keyboard: TextInputType.number),
            const SizedBox(height: 10),
            _tf(g, 'Genre'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F3A2E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  if (t.text.trim().isEmpty) {
                    _snack('Title required');
                    return;
                  }
                  setState(() {
                    var data = Book(
                      id:
                          existing?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      title: t.text.trim(),
                      author: a.text.trim().isEmpty ? 'Unknown' : a.text.trim(),
                      price: double.tryParse(p.text.trim()) ?? 0.0,
                      rating: existing?.rating ?? 0.0,
                      category: g.text.trim().isEmpty
                          ? 'General'
                          : g.text.trim(),
                      imageUrl:
                          existing?.imageUrl ??
                          'https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=300&auto=format&fit=crop',
                      description: existing?.description ?? '',
                    );
                    if (existing == null) {
                      widget.allBooks.add(data);
                    } else {
                      widget.allBooks[idx!] = data;
                    }
                  });
                  Navigator.pop(context);
                  _snack(existing == null ? 'Book added' : 'Book updated');
                },
                child: Text(
                  existing == null ? 'Add' : 'Save',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(Book b) {
    var palette = [
      Colors.blue,
      Colors.red,
      Colors.teal,
      Colors.brown,
      Colors.indigo,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.cyan,
      Colors.pink,
    ];
    return palette[b.id.hashCode.abs() % palette.length];
  }

  void _confirmDelete(int idx) {
    var book = widget.allBooks[idx];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete book?'),
        content: Text('Remove "${book.title}" from catalog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => widget.allBooks.removeAt(idx));
              Navigator.pop(context);
              _snack('Book deleted');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), duration: const Duration(seconds: 1)),
    );
  }

  Widget _tf(TextEditingController c, String hint, {TextInputType? keyboard}) =>
      TextField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    var items = _vis;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F1E8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Books',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text(
                'Add',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F3A2E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchCtl,
                onChanged: (v) => setState(() => _q = v),
                decoration: const InputDecoration(
                  hintText: 'Search catalog',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                  suffixIcon: null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'No books found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      var b = items[i];
                      var realIdx = widget.allBooks.indexOf(b);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _colorFor(b),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  b.title.substring(0, 2).toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${b.author} · \$${b.price.toStringAsFixed(2)} · ${b.category}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.grey,
                              ),
                              onPressed: () =>
                                  _openForm(existing: b, idx: realIdx),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.grey,
                              ),
                              onPressed: () => _confirmDelete(realIdx),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
