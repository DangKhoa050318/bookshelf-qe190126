import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../state/book_store.dart';
import '../theme.dart';
import '../widgets/book_form_fields.dart';
import '../widgets/book_tile.dart';
import '../widgets/common.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.bookId});

  final String bookId;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // Changes when the title or author is edited, because the id depends on them.
  late String _id = widget.bookId;
  Book? _lastBook;

  BookFormData? _form;
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _submitted = false;
  bool _saving = false;
  bool _leaving = false;
  String? _error;

  @override
  void dispose() {
    _form?.dispose();
    super.dispose();
  }

  void _startEdit(Book book) {
    setState(() {
      _form?.dispose();
      _form = BookFormData(book);
      _formKey = GlobalKey<FormState>();
      _submitted = false;
      _error = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _form?.dispose();
      _form = null;
      _error = null;
    });
  }

  Future<void> _save(Book book) async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final newId =
          await context.read<BookStore>().updateBook(book, _form!.toInput());
      if (!mounted) return;
      setState(() {
        _id = newId;
        _form?.dispose();
        _form = null;
      });
    } on FirebaseException catch (e) {
      if (mounted) setState(() => _error = e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleFavorite(Book book) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<BookStore>().toggleFavorite(book);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _delete(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete book'),
        content: Text('Delete "${book.title}" from your list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              minimumSize: const Size(64, 40),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final store = context.read<BookStore>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _leaving = true);
    context.pop();
    // The list updates at once; if Firestore refuses, the book comes back.
    store.deleteBook(book).catchError((Object e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BookStore>();
    final current = store.byId(_id);
    if (current != null) _lastBook = current;
    final book = current ?? (_saving || _leaving ? _lastBook : null);

    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail')),
        body: Center(
          child: store.loading
              ? const CircularProgressIndicator()
              : const Text('Book not found'),
        ),
      );
    }

    final editing = _form != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit book' : 'Detail'),
        actions: [
          if (!editing)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _startEdit(book),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [editing ? _buildEdit(book) : _buildView(book)],
        ),
      ),
    );
  }

  Widget _buildView(Book book) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.title, style: text.headlineSmall),
                        const SizedBox(height: Gap.xs),
                        Text('by ${book.author}', style: text.titleSmall),
                      ],
                    ),
                  ),
                  FavoriteButton(
                    favorite: book.favorite,
                    onPressed: () => _toggleFavorite(book),
                  ),
                ],
              ),
              const Divider(height: Gap.lg),
              _DetailRow(label: 'Title', value: book.title),
              _DetailRow(label: 'Author', value: book.author),
              _DetailRow(label: 'Genre', value: book.genre),
              _DetailRow(label: 'Status', value: book.status),
              _DetailRow(
                label: 'Rating',
                value: book.rating == null ? 'Not rated' : '${book.rating} / 5',
              ),
              _DetailRow(
                label: 'Favorite',
                value: book.favorite ? 'Yes' : 'No',
              ),
              _DetailRow(
                label: 'Notes',
                value: book.notes.isEmpty ? 'No notes' : book.notes,
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _startEdit(book),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(width: Gap.sm),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.error,
                  side: BorderSide(color: scheme.error),
                ),
                onPressed: () => _delete(book),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEdit(Book book) {
    return SectionCard(
      title: 'Edit book',
      child: Form(
        key: _formKey,
        autovalidateMode:
            _submitted ? AutovalidateMode.always : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BookFormFields(data: _form!),
            const SizedBox(height: Gap.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _cancelEdit,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: PrimaryButton(
                    label: 'Save',
                    icon: Icons.save_outlined,
                    busy: _saving,
                    onPressed: () => _save(book),
                  ),
                ),
              ],
            ),
            if (_error != null) FormMessage(text: _error!),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: text.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: text.bodyLarge)),
        ],
      ),
    );
  }
}
