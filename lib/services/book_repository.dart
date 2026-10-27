import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/book.dart';

/// All reads and writes of the `books` collection.
class BookRepository {
  BookRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _books =>
      _db.collection('books');

  Stream<List<Book>> watchBooks(String userId) => _books
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snap) => snap.docs.map(Book.fromDoc).toList()..sort(Book.compare));

  /// Saves a new book. Runs as a transaction so nothing shows up in the list
  /// until Firestore has accepted it (a refused duplicate never flickers in).
  Future<void> add(String userId, BookInput input) async {
    final id = Book.keyFor(userId, input.title, input.author);
    final ref = _books.doc(id);
    await _db.runTransaction((tx) async {
      tx.set(ref, {
        ...input.toMap(),
        'id': id,
        'userId': userId,
        'favorite': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Updates a book and returns its (possibly new) id. Changing the title or
  /// author changes the document id, so the book is moved to the new id.
  Future<String> update(Book book, BookInput input) async {
    final newId = Book.keyFor(book.userId, input.title, input.author);
    if (newId == book.id) {
      await _books.doc(book.id).update(input.toMap());
      return book.id;
    }
    await _db.runTransaction((tx) async {
      tx.delete(_books.doc(book.id));
      tx.set(_books.doc(newId), {
        ...input.toMap(),
        'id': newId,
        'userId': book.userId,
        'favorite': book.favorite,
        'createdAt': book.createdAt ?? FieldValue.serverTimestamp(),
      });
    });
    return newId;
  }

  Future<void> setFavorite(Book book, bool favorite) =>
      _books.doc(book.id).update({'favorite': favorite});

  Future<void> delete(Book book) => _books.doc(book.id).delete();
}
