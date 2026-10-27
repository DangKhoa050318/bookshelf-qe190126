import 'package:bookshelf/models/book.dart';
import 'package:bookshelf/state/book_store.dart';
import 'package:bookshelf/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

Book _book(
  String title, {
  String author = 'A',
  String status = 'To Read',
  bool favorite = false,
}) =>
    Book(
      id: '$title|$author',
      userId: 'u',
      title: title,
      author: author,
      genre: 'Fiction',
      status: status,
      rating: null,
      favorite: favorite,
      notes: '',
      createdAt: null,
    );

void main() {
  group('Book.keyFor', () {
    test('matches the hash computed by the security rules', () {
      // sha256("uid123|dune|frank herbert"), computed with Node's crypto.
      expect(
        Book.keyFor('uid123', '  Dune ', 'FRANK Herbert'),
        'c3467bfaba438a02c657d1bb84dffbee1617b7c214c200da18c05b666dfeca17',
      );
    });

    test('ignores case and surrounding spaces', () {
      expect(
        Book.keyFor('u', 'Dune', 'Frank Herbert'),
        Book.keyFor('u', ' dune', 'frank herbert '),
      );
      expect(
        Book.keyFor('u', 'Dune', 'Frank Herbert'),
        isNot(Book.keyFor('v', 'Dune', 'Frank Herbert')),
      );
    });
  });

  test('books sort by title ignoring case, then by author', () {
    final books = [
      _book('dune', author: 'Z'),
      _book('Emma'),
      _book('Dune', author: 'b'),
      _book('animal Farm'),
    ]..sort(Book.compare);
    expect(
      books.map((b) => '${b.title}/${b.author}'),
      ['animal Farm/A', 'Dune/b', 'dune/Z', 'Emma/A'],
    );
  });

  group('BookSummary', () {
    test('counts books, favorites and statuses, most first', () {
      final s = BookSummary.of([
        _book('a', status: 'Finished', favorite: true),
        _book('b', status: 'Finished'),
        _book('c', status: 'Reading', favorite: true),
      ]);
      expect(s.total, 3);
      expect(s.favorites, 2);
      expect(s.byStatus.map((e) => '${e.key}:${e.value}'),
          ['Finished:2', 'Reading:1']);
    });

    test('equal counts follow To Read, Reading, Finished', () {
      final s = BookSummary.of([
        _book('a', status: 'Finished'),
        _book('b', status: 'Reading'),
        _book('c', status: 'To Read'),
      ]);
      expect(s.byStatus.map((e) => e.key), ['To Read', 'Reading', 'Finished']);
    });

    test('empty list has no rows', () {
      final s = BookSummary.of([]);
      expect(s.total, 0);
      expect(s.byStatus, isEmpty);
    });
  });

  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('abc'), 'Please enter a valid email address');
      expect(Validators.email('a@b.co'), isNull);
    });

    test('passwords', () {
      expect(Validators.loginPassword(''), 'Password is required');
      expect(Validators.loginPassword('1'), isNull);
      expect(Validators.registerPassword(''), 'Password is required');
      expect(Validators.registerPassword('12345'),
          'Password must be at least 6 characters');
      expect(Validators.registerPassword('123456'), isNull);
      expect(Validators.confirmPassword('', 'x'), 'Confirm password is required');
      expect(Validators.confirmPassword('y', 'x'), 'Passwords do not match');
      expect(Validators.confirmPassword('x', 'x'), isNull);
    });

    test('title and author', () {
      expect(Validators.title('   '), 'Title is required');
      expect(Validators.title('T' * 101), 'Title must be at most 100 characters');
      expect(Validators.title('T' * 100), isNull);
      expect(Validators.author(''), 'Author is required');
      expect(Validators.author('A' * 61), 'Author must be at most 60 characters');
      expect(Validators.author('A' * 60), isNull);
    });

    test('genre, status, rating, notes', () {
      expect(Validators.genre(null), 'Please choose a genre');
      expect(Validators.status(null), 'Please choose a status');
      for (final bad in ['6', '-1', '3.5', 'abc', '10']) {
        expect(Validators.rating(bad), 'Rating must be a whole number from 0 to 5');
      }
      for (final ok in ['', ' ', '0', '5', ' 3 ']) {
        expect(Validators.rating(ok), isNull);
      }
      expect(Validators.notes('n' * 301), 'Notes must be at most 300 characters');
      expect(Validators.notes('n' * 300), isNull);
    });
  });
}
