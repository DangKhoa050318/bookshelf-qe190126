// Tests firestore.rules against the Firestore emulator.
// Run from the project root: firebase emulators:exec --only firestore "npm --prefix rules_test test"
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  addDoc,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
  Timestamp,
} from 'firebase/firestore';

const ALICE = 'alice';
const BOB = 'bob';

const key = (uid, title, author) =>
  createHash('sha256')
    .update(`${uid}|${title.trim().toLowerCase()}|${author.trim().toLowerCase()}`, 'utf8')
    .digest('hex');

const book = (uid, overrides = {}) => {
  const data = {
    userId: uid,
    title: 'Dune',
    author: 'Frank Herbert',
    genre: 'Fiction',
    status: 'To Read',
    rating: null,
    favorite: false,
    notes: '',
    createdAt: serverTimestamp(),
    ...overrides,
  };
  data.id = key(uid, String(data.title ?? ''), String(data.author ?? ''));
  return data;
};

let env;
const db = (uid) =>
  uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();

// Writes a book the way the app does (document id = key, no transaction needed here).
const save = (uid, data, asUser = uid) =>
  setDoc(doc(db(asUser), 'books', key(uid, String(data.title), String(data.author))), data);

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-bookshelf',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});
beforeEach(() => env.clearFirestore());
after(() => env.cleanup());

describe('create', () => {
  test('valid book is accepted', () => assertSucceeds(save(ALICE, book(ALICE))));

  test('rating 0..5, notes of 300, title of 100, author of 60 are accepted', () =>
    assertSucceeds(
      save(ALICE, book(ALICE, {
        title: 'T'.repeat(100),
        author: 'A'.repeat(60),
        rating: 5,
        notes: 'n'.repeat(300),
      })),
    ));

  test('rating 0 is accepted', () => assertSucceeds(save(ALICE, book(ALICE, { rating: 0 }))));

  test('a book without optional fields is accepted', async () => {
    const { rating, favorite, notes, id, ...minimal } = book(ALICE);
    await assertSucceeds(save(ALICE, minimal));
  });

  const bad = {
    'missing title': { title: undefined },
    'empty title': { title: '' },
    'spaces-only title': { title: '    ' },
    'title of 101': { title: 'T'.repeat(101) },
    'empty author': { author: '' },
    'spaces-only author': { author: '   ' },
    'author of 61': { author: 'A'.repeat(61) },
    'unknown genre': { genre: 'Poetry' },
    'lower-case genre': { genre: 'fiction' },
    'missing genre': { genre: undefined },
    'unknown status': { status: 'Done' },
    'missing status': { status: undefined },
    'rating 6': { rating: 6 },
    'rating -1': { rating: -1 },
    'rating 3.5': { rating: 3.5 },
    'rating as text': { rating: '3' },
    'notes of 301': { notes: 'n'.repeat(301) },
    'favorite not a bool': { favorite: 'yes' },
    'non-string title': { title: 42 },
  };
  for (const [name, overrides] of Object.entries(bad)) {
    test(`refuses ${name}`, () => {
      const data = book(ALICE, overrides);
      delete data.id; // only the broken field should cause the refusal
      for (const k of Object.keys(data)) if (data[k] === undefined) delete data[k];
      return assertFails(
        setDoc(doc(db(ALICE), 'books', key(ALICE, String(overrides.title ?? 'Dune'), String(overrides.author ?? 'Frank Herbert'))), data),
      );
    });
  }

  test('refuses a book saved for another person', () =>
    assertFails(save(BOB, book(BOB), ALICE)));

  test('refuses a book with userId of another person under own key', () =>
    assertFails(setDoc(doc(db(ALICE), 'books', key(ALICE, 'Dune', 'Frank Herbert')), { ...book(ALICE), userId: BOB })));

  test('refuses a random document id', () => assertFails(addDoc(collection(db(ALICE), 'books'), book(ALICE))));

  test('refuses a mismatching id field', () =>
    assertFails(save(ALICE, { ...book(ALICE), id: 'something-else' })));

  test('refuses visitors', () =>
    assertFails(setDoc(doc(db(null), 'books', key(ALICE, 'Dune', 'Frank Herbert')), book(ALICE))));
});

describe('duplicates', () => {
  beforeEach(() => save(ALICE, book(ALICE)));

  test('same title + author with different case is refused (setDoc)', () =>
    assertFails(save(ALICE, book(ALICE, { title: 'dune', author: 'FRANK HERBERT' }))));

  test('exact same book again is refused', () => assertFails(save(ALICE, book(ALICE))));

  test('duplicate with copied createdAt-less data is refused', async () => {
    const { createdAt, ...noDate } = book(ALICE, { title: 'DUNE' });
    await assertFails(save(ALICE, noDate));
  });

  test('duplicate with a client timestamp is refused', () =>
    assertFails(save(ALICE, book(ALICE, { title: ' Dune ', createdAt: Timestamp.now() }))));

  test('another person may save the same book', () => assertSucceeds(save(BOB, book(BOB))));
});

describe('read', () => {
  beforeEach(async () => {
    await save(ALICE, book(ALICE));
    await save(BOB, book(BOB, { title: 'Emma', author: 'Jane Austen' }));
  });

  test('owner can read own book', () =>
    assertSucceeds(getDoc(doc(db(ALICE), 'books', key(ALICE, 'Dune', 'Frank Herbert')))));

  test('owner can query own books', () =>
    assertSucceeds(getDocs(query(collection(db(ALICE), 'books'), where('userId', '==', ALICE)))));

  test("cannot read another person's book", () =>
    assertFails(getDoc(doc(db(ALICE), 'books', key(BOB, 'Emma', 'Jane Austen')))));

  test('cannot list the whole collection', () => assertFails(getDocs(collection(db(ALICE), 'books'))));

  test("cannot query another person's books", () =>
    assertFails(getDocs(query(collection(db(ALICE), 'books'), where('userId', '==', BOB)))));

  test('visitors cannot read', () =>
    assertFails(getDoc(doc(db(null), 'books', key(ALICE, 'Dune', 'Frank Herbert')))));
});

// Reads a document as stored, bypassing the rules.
const stored = async (id) => {
  let data;
  await env.withSecurityRulesDisabled(async (ctx) => {
    data = (await getDoc(doc(ctx.firestore(), 'books', id))).data();
  });
  return data;
};

describe('update and delete', () => {
  const aliceId = key(ALICE, 'Dune', 'Frank Herbert');
  beforeEach(() => save(ALICE, book(ALICE)));

  test('owner can toggle favorite', () =>
    assertSucceeds(updateDoc(doc(db(ALICE), 'books', aliceId), { favorite: true })));

  test('owner can edit fields that keep the same id', () =>
    assertSucceeds(updateDoc(doc(db(ALICE), 'books', aliceId), {
      title: 'DUNE', status: 'Finished', rating: 4, notes: 'Great',
    })));

  test('owner can rename (move to the new id) in one batch', async () => {
    const old = await stored(aliceId);
    const fs = db(ALICE);
    const batch = writeBatch(fs);
    const newId = key(ALICE, 'Dune Messiah', 'Frank Herbert');
    batch.delete(doc(fs, 'books', aliceId));
    batch.set(doc(fs, 'books', newId), { ...old, title: 'Dune Messiah', id: newId });
    await assertSucceeds(batch.commit());
  });

  test('renaming onto an existing book is refused', async () => {
    await save(ALICE, book(ALICE, { title: 'Emma', author: 'Jane Austen' }));
    const old = await stored(aliceId);
    const fs = db(ALICE);
    const batch = writeBatch(fs);
    const newId = key(ALICE, 'Emma', 'Jane Austen');
    batch.delete(doc(fs, 'books', aliceId));
    batch.set(doc(fs, 'books', newId), { ...old, title: 'Emma', author: 'Jane Austen', id: newId });
    await assertFails(batch.commit());
  });

  test('editing the title without moving the id is refused', () =>
    assertFails(updateDoc(doc(db(ALICE), 'books', aliceId), { title: 'Other' })));

  test('bad data in an update is refused', async () => {
    const ref = doc(db(ALICE), 'books', aliceId);
    await assertFails(updateDoc(ref, { rating: 9 }));
    await assertFails(updateDoc(ref, { genre: 'Poetry' }));
    await assertFails(updateDoc(ref, { status: 'Done' }));
    await assertFails(updateDoc(ref, { notes: 'n'.repeat(301) }));
    await assertFails(updateDoc(ref, { createdAt: Timestamp.now() }));
  });

  test('cannot give the book to another person', () =>
    assertFails(updateDoc(doc(db(ALICE), 'books', aliceId), { userId: BOB })));

  test("cannot change another person's book", () =>
    assertFails(updateDoc(doc(db(BOB), 'books', aliceId), { favorite: true })));

  test('owner can delete', () => assertSucceeds(deleteDoc(doc(db(ALICE), 'books', aliceId))));

  test("cannot delete another person's book", () =>
    assertFails(deleteDoc(doc(db(BOB), 'books', aliceId))));

  test('visitors cannot update or delete', async () => {
    await assertFails(updateDoc(doc(db(null), 'books', aliceId), { favorite: true }));
    await assertFails(deleteDoc(doc(db(null), 'books', aliceId)));
  });
});
