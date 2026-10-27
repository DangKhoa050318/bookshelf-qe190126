import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme.dart';
import '../utils/validators.dart';
import 'common.dart';

/// Holds the values of the Add Book and Edit Book forms.
class BookFormData {
  BookFormData([Book? book])
      : title = TextEditingController(text: book?.title),
        author = TextEditingController(text: book?.author),
        rating = TextEditingController(text: book?.rating?.toString()),
        notes = TextEditingController(text: book?.notes),
        genre = book == null || !kGenres.contains(book.genre) ? null : book.genre,
        status =
            book == null || !kStatuses.contains(book.status) ? null : book.status;

  final TextEditingController title;
  final TextEditingController author;
  final TextEditingController rating;
  final TextEditingController notes;
  String? genre;
  String? status;

  /// Only call after the form validated.
  BookInput toInput() {
    final r = rating.text.trim();
    return BookInput(
      title: title.text,
      author: author.text,
      genre: genre!,
      status: status!,
      rating: r.isEmpty ? null : int.parse(r),
      notes: notes.text,
    );
  }

  void clear() {
    title.clear();
    author.clear();
    rating.clear();
    notes.clear();
    genre = null;
    status = null;
  }

  void dispose() {
    title.dispose();
    author.dispose();
    rating.dispose();
    notes.dispose();
  }
}

/// The book fields shared by the Add Book form and the Detail edit mode.
/// Place inside a [Form]; rebuild the [Form] with a new key after
/// [BookFormData.clear] so the dropdowns reset too.
class BookFormFields extends StatelessWidget {
  const BookFormFields({super.key, required this.data});

  final BookFormData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: data.title,
          label: 'Title',
          validator: Validators.title,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: Gap.md),
        AppTextField(
          controller: data.author,
          label: 'Author',
          validator: Validators.author,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: Gap.md),
        _ChoiceField(
          label: 'Genre',
          emptyChoice: 'Choose genre',
          options: kGenres,
          initialValue: data.genre,
          validator: Validators.genre,
          onChanged: (v) => data.genre = v,
        ),
        const SizedBox(height: Gap.md),
        _ChoiceField(
          label: 'Status',
          emptyChoice: 'Choose status',
          options: kStatuses,
          initialValue: data.status,
          validator: Validators.status,
          onChanged: (v) => data.status = v,
        ),
        const SizedBox(height: Gap.md),
        AppTextField(
          controller: data.rating,
          label: 'Rating (0-5, optional)',
          validator: Validators.rating,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: Gap.md),
        AppTextField(
          controller: data.notes,
          label: 'Notes (optional)',
          validator: Validators.notes,
          keyboardType: TextInputType.multiline,
          maxLines: 4,
        ),
      ],
    );
  }
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.emptyChoice,
    required this.options,
    required this.initialValue,
    required this.validator,
    required this.onChanged,
  });

  final String label;
  final String emptyChoice;
  final List<String> options;
  final String? initialValue;
  final FormFieldValidator<String?> validator;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: initialValue,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      hint: Text(emptyChoice),
      validator: validator,
      onChanged: onChanged,
      items: [
        DropdownMenuItem<String?>(value: null, child: Text(emptyChoice)),
        for (final o in options)
          DropdownMenuItem<String?>(value: o, child: Text(o)),
      ],
    );
  }
}
