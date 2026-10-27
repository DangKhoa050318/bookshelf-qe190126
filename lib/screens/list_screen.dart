import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../services/auth_service.dart';
import '../state/book_store.dart';
import '../theme.dart';
import '../widgets/add_book_card.dart';
import '../widgets/book_tile.dart';
import '../widgets/common.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.text = context.read<BookStore>().search;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(Book book) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<BookStore>().toggleFavorite(book);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final store = context.watch<BookStore>();
    final books = store.visibleBooks;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BookShelf'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: scheme.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: Gap.md),
            height: 48,
            child: Row(
              children: [
                Icon(Icons.account_circle, color: scheme.onPrimaryContainer),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: Text(
                    auth.user?.email ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.read<AuthService>().signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [
            const AddBookCard(),
            const SizedBox(height: Gap.md),
            _FilterCard(searchController: _search),
            const SizedBox(height: Gap.md),
            _SummaryCard(summary: store.summary),
            const SizedBox(height: Gap.md),
            Text('Your books', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Gap.sm),
            if (store.loading)
              const Padding(
                padding: EdgeInsets.all(Gap.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (store.loadError != null)
              FormMessage(text: store.loadError!)
            else if (books.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: Gap.lg),
                child: Text('No books found', textAlign: TextAlign.center),
              )
            else
              for (final book in books) ...[
                BookTile(
                  key: ValueKey(book.id),
                  book: book,
                  onOpen: () {
                    // Keep the keyboard closed when coming back from Detail.
                    FocusScope.of(context).unfocus();
                    context.push('/books/${book.id}');
                  },
                  onToggleFavorite: () => _toggleFavorite(book),
                ),
                const SizedBox(height: Gap.sm),
              ],
          ],
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.searchController});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BookStore>();
    return SectionCard(
      title: 'Filter and search',
      trailing: TextButton.icon(
        onPressed: () {
          searchController.clear();
          store.clearFilters();
        },
        icon: const Icon(Icons.clear_all),
        label: const Text('Clear'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: searchController,
            label: 'Search title or author',
            prefixIcon: Icons.search,
            textInputAction: TextInputAction.search,
            onChanged: store.setSearch,
          ),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  label: 'Genre',
                  value: store.genreFilter,
                  options: kGenres,
                  onChanged: store.setGenreFilter,
                ),
              ),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: _FilterDropdown(
                  label: 'Status',
                  value: store.statusFilter,
                  options: kStatuses,
                  onChanged: store.setStatusFilter,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Favorites only'),
            value: store.favoritesOnly,
            onChanged: store.setFavoritesOnly,
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          isDense: true,
          onChanged: onChanged,
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('All')),
            for (final o in options)
              DropdownMenuItem<String?>(value: o, child: Text(o)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final BookSummary summary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SectionCard(
      title: 'Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: Gap.lg,
            runSpacing: Gap.xs,
            children: [
              Text('Books: ${summary.total}', style: text.titleSmall),
              Text('Favorites: ${summary.favorites}', style: text.titleSmall),
            ],
          ),
          if (summary.byStatus.isNotEmpty) ...[
            const Divider(height: Gap.lg),
            for (final row in summary.byStatus)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text(row.key)),
                    Text('${row.value}', style: text.titleSmall),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
