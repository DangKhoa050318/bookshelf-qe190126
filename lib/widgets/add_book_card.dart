import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/book_store.dart';
import '../theme.dart';
import 'book_form_fields.dart';
import 'common.dart';

/// The "Add a book" form on the List screen.
class AddBookCard extends StatefulWidget {
  const AddBookCard({super.key});

  @override
  State<AddBookCard> createState() => _AddBookCardState();
}

class _AddBookCardState extends State<AddBookCard> {
  var _formKey = GlobalKey<FormState>();
  final _data = BookFormData();
  bool _submitted = false;
  bool _busy = false;
  bool _expanded = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _error = null;
      _success = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<BookStore>().addBook(_data.toInput());
      if (!mounted) return;
      setState(() {
        _data.clear();
        _formKey = GlobalKey<FormState>(); // resets the dropdowns
        _submitted = false;
        _success = 'Book added';
      });
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Book added'),
          duration: Duration(seconds: 6),
        ));
    } on FirebaseException catch (e) {
      if (mounted) setState(() => _error = e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Add a book',
      titleGap: _expanded ? Gap.md : 0,
      trailing: IconButton(
        tooltip: _expanded ? 'Hide form' : 'Show form',
        icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
        onPressed: () => setState(() => _expanded = !_expanded),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kept in the tree while collapsed so typed values are not lost.
          Offstage(
            offstage: !_expanded,
            child: Form(
              key: _formKey,
              autovalidateMode: _submitted
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BookFormFields(data: _data),
                  const SizedBox(height: Gap.lg),
                  PrimaryButton(
                    label: 'Add book',
                    icon: Icons.add,
                    busy: _busy,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
          if (_success != null) FormMessage(text: _success!, isError: false),
          if (_error != null) FormMessage(text: _error!),
        ],
      ),
    );
  }
}
