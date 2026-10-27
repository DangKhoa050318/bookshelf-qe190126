import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../services/auth_service.dart';
import '../services/book_repository.dart';

/// Counts describing the books currently shown.
class BookSummary {
  const BookSummary(this.total, this.favorites, this.byStatus);

  final int total;
  final int favorites;

  /// One entry per status that appears, most books first; ties follow
  /// the order To Read, Reading, Finished.
  final List<MapEntry<String, int>> byStatus;

  factory BookSummary.of(List<Book> books) {
    final counts = {for (final s in kStatuses) s: 0};
    for (final b in books) {
      if (counts.containsKey(b.status)) counts[b.status] = counts[b.status]! + 1;
    }
    final rows = counts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return kStatuses.indexOf(a.key).compareTo(kStatuses.indexOf(b.key));
      });
    return BookSummary(
      books.length,
      books.where((b) => b.favorite).length,
      rows,
    );
  }
}

/// The logged-in user's books plus the List screen's filters, shared by the
/// List and Detail screens.
class BookStore extends ChangeNotifier {
  BookStore(this._auth, this._repo) {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final AuthService _auth;
  final BookRepository _repo;

  StreamSubscription<List<Book>>? _sub;
  String? _userId;
  List<Book> _books = const [];
  bool _loading = false;
  String? _loadError;

  String? _genre;
  String? _status;
  bool _favoritesOnly = false;
  String _search = '';

  bool get loading => _loading;
  String? get loadError => _loadError;
  String? get genreFilter => _genre;
  String? get statusFilter => _status;
  bool get favoritesOnly => _favoritesOnly;
  String get search => _search;

  List<Book> get visibleBooks {
    final query = _search.trim().toLowerCase();
    return _books.where((b) {
      if (_genre != null && b.genre != _genre) return false;
      if (_status != null && b.status != _status) return false;
      if (_favoritesOnly && !b.favorite) return false;
      if (query.isNotEmpty &&
          !b.title.toLowerCase().contains(query) &&
          !b.author.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  BookSummary get summary => BookSummary.of(visibleBooks);

  Book? byId(String id) {
    for (final b in _books) {
      if (b.id == id) return b;
    }
    return null;
  }

  void setGenreFilter(String? genre) {
    _genre = genre;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _status = status;
    notifyListeners();
  }

  void setFavoritesOnly(bool value) {
    _favoritesOnly = value;
    notifyListeners();
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void clearFilters() {
    _resetFilters();
    notifyListeners();
  }

  Future<void> addBook(BookInput input) => _repo.add(_requireUser(), input);

  Future<String> updateBook(Book book, BookInput input) =>
      _repo.update(book, input);

  Future<void> toggleFavorite(Book book) =>
      _repo.setFavorite(book, !book.favorite);

  Future<void> deleteBook(Book book) => _repo.delete(book);

  String _requireUser() {
    final id = _userId;
    if (id == null) throw StateError('Not logged in');
    return id;
  }

  void _resetFilters() {
    _genre = null;
    _status = null;
    _favoritesOnly = false;
    _search = '';
  }

  void _onAuthChanged() {
    final userId = _auth.user?.uid;
    if (userId == _userId) return;
    _userId = userId;
    _sub?.cancel();
    _sub = null;
    _books = const [];
    _loadError = null;
    _resetFilters();
    _loading = userId != null;
    if (userId != null) {
      _sub = _repo.watchBooks(userId).listen(
        (books) {
          _books = books;
          _loading = false;
          _loadError = null;
          notifyListeners();
        },
        onError: (Object e) {
          _loading = false;
          _loadError = e.toString();
          notifyListeners();
        },
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _sub?.cancel();
    super.dispose();
  }
}
