import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/store_repository.dart';

class BookEditorSheet extends StatefulWidget {
  const BookEditorSheet({super.key, required this.repository, this.existing});
  final StoreRepository repository;
  final Book? existing;
  @override
  State<BookEditorSheet> createState() => _BookEditorSheetState();
}

class _BookEditorSheetState extends State<BookEditorSheet> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title,
      author,
      price,
      genre,
      cover,
      description;
  late DateTime releaseDate;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    title = TextEditingController(text: b?.title ?? '');
    author = TextEditingController(text: b?.author ?? '');
    price = TextEditingController(text: b?.price.toStringAsFixed(2) ?? '');
    genre = TextEditingController(text: b?.category ?? '');
    cover = TextEditingController(text: b?.imageUrl ?? '');
    description = TextEditingController(text: b?.description ?? '');
    releaseDate = b?.releaseDate ?? DateTime.now();
  }

  @override
  void dispose() {
    for (final c in [title, author, price, genre, cover, description]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget input(
    TextEditingController c,
    String label,
    int max, {
    int lines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      enabled: !saving,
      maxLength: max,
      maxLines: lines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator:
          validator ??
          (value) => value == null || value.trim().isEmpty ? 'Required' : null,
    ),
  );
  Future<void> submit() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await widget.repository.saveBook(
        Book(
          id:
              widget.existing?.id ??
              DateTime.now().microsecondsSinceEpoch.toString(),
          title: title.text.trim(),
          author: author.text.trim(),
          price: double.parse(price.text.trim()),
          rating: widget.existing?.rating ?? 0,
          category: genre.text.trim(),
          imageUrl: cover.text.trim(),
          description: description.text.trim(),
          releaseDate: releaseDate,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Book could not be saved. Check the details and connection.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? 'Add book' : 'Edit book',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 18),
              input(title, 'Title', 300),
              input(author, 'Author', 200),
              input(
                price,
                'Price',
                12,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  final n = double.tryParse(v);
                  return !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(v) ||
                          n == null ||
                          !n.isFinite ||
                          n > 100000
                      ? 'Enter a price from 0 to 100000 with up to two decimals'
                      : null;
                },
              ),
              input(genre, 'Genre', 100),
              input(
                cover,
                'Cover image URL',
                2000,
                keyboard: TextInputType.url,
                validator: (value) {
                  final uri = Uri.tryParse(value?.trim() ?? '');
                  return uri == null ||
                          uri.scheme != 'https' ||
                          uri.host.isEmpty
                      ? 'Enter an HTTPS image URL'
                      : null;
                },
              ),
              input(
                description,
                'Description',
                20000,
                lines: 4,
                validator: (_) => null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Release date'),
                subtitle: Text(releaseDate.toIso8601String().split('T').first),
                trailing: const Icon(Icons.calendar_month),
                onTap: saving
                    ? null
                    : () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: releaseDate,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (date != null && mounted)
                          setState(() => releaseDate = date);
                      },
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: saving ? null : submit,
                child: Text(saving ? 'Saving...' : 'Save book'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
