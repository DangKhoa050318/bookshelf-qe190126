# BookShelf

PRM393 practical exam (Fall 2026) — QE190126, Nguyễn Xuân Đăng Khoa.

A Flutter app where each person keeps a private list of books, sorted into reading
statuses and genres, with a favorite flag. Login and data use Firebase
Authentication (Email/Password) and Cloud Firestore.

## Run

```sh
flutter pub get
flutter run            # Android device or emulator
flutter build apk --release
```

The app connects to the Firebase project `bookshelf-qe190126` through the
client-side config only (`lib/firebase_options.dart`,
`android/app/google-services.json`). To use another project, replace those two
files (for example with `flutterfire configure`) and publish `firestore.rules`.

> On Windows, build from a folder whose path contains only ASCII characters;
> the Android toolchain cannot read paths with characters such as `ử`.

## Structure

| Path | What it holds |
| --- | --- |
| `lib/models/book.dart` | `Book` model, genres/statuses, document-id key |
| `lib/services/` | Firebase Auth wrapper, Firestore repository |
| `lib/state/book_store.dart` | Shared state: user's books, filters, search, summary |
| `lib/router.dart` | Routes and login redirects (go_router) |
| `lib/screens/` | Home, Login, Register, List, Detail |
| `lib/widgets/` | Shared inputs, buttons, cards, book form |
| `firestore.rules` | Security rules (validation, ownership, duplicates) |
| `rules_test/` | Rules tests against the Firestore emulator |
| `test/` | Unit tests for validators, sorting, summary, key |

## Duplicate books

The `books` collection must refuse the same title + author for one person
(ignoring letter case). Security rules cannot query, so each book's document id
is `sha256("<uid>|<title>|<author>")` with title and author trimmed and
lower-cased. The rules recompute this id, so a second copy lands on the same
document and is refused; editing keeps `createdAt` unchanged, which tells a real
edit apart from a duplicate save. Changing a title or author moves the book to its
new id in one transaction.

## Tests

```sh
flutter test
# Security rules (needs Firebase CLI and Java):
npm --prefix rules_test install
firebase emulators:exec --only firestore --project demo-bookshelf "npm --prefix rules_test test"
```
