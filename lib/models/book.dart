import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

const List<String> kGenres = ['Fiction', 'Non-Fiction', 'Academic', 'Other'];
const List<String> kStatuses = ['To Read', 'Reading', 'Finished'];

/// A book as stored in the `books` collection.
class Book {
  const Book({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    required this.rating,
    required this.favorite,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String author;
  final String genre;
  final String status;
  final int? rating;
  final bool favorite;
  final String notes;
  final Timestamp? createdAt;

  factory Book.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Book(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      title: d['title'] as String? ?? '',
      author: d['author'] as String? ?? '',
      genre: d['genre'] as String? ?? '',
      status: d['status'] as String? ?? '',
      rating: (d['rating'] as num?)?.toInt(),
      favorite: d['favorite'] == true,
      notes: d['notes'] as String? ?? '',
      createdAt: d['createdAt'] is Timestamp ? d['createdAt'] as Timestamp : null,
    );
  }

  /// Document id for a book: the same person + title + author (ignoring case
  /// and surrounding spaces) always maps to the same id, which is how the
  /// security rules refuse duplicates. Must match `bookKey()` in firestore.rules.
  static String keyFor(String userId, String title, String author) {
    final raw =
        '$userId|${title.trim().toLowerCase()}|${author.trim().toLowerCase()}';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  /// Alphabetical by title (case-insensitive), then by author.
  static int compare(Book a, Book b) {
    final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    if (byTitle != 0) return byTitle;
    final byAuthor = a.author.toLowerCase().compareTo(b.author.toLowerCase());
    if (byAuthor != 0) return byAuthor;
    return a.id.compareTo(b.id);
  }
}

/// The user-editable part of a book, as entered in the Add / Edit forms.
class BookInput {
  const BookInput({
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    required this.rating,
    required this.notes,
  });

  final String title;
  final String author;
  final String genre;
  final String status;
  final int? rating;
  final String notes;

  Map<String, dynamic> toMap() => {
        'title': title.trim(),
        'author': author.trim(),
        'genre': genre,
        'status': status,
        'rating': rating,
        'notes': notes.trim(),
      };
}
