import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _features = [
    (
      Icons.menu_book_outlined,
      'Track your books',
      'Keep a private list of the books you own or want to read.',
    ),
    (
      Icons.view_list_outlined,
      'Sort by status',
      'Mark each book as To Read, Reading or Finished and filter by genre.',
    ),
    (
      Icons.star_outline,
      'Rate your favorites',
      'Give books a rating from 0 to 5 and star the ones you love.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('BookShelf'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: scheme.onPrimary),
            onPressed: () => context.push('/login'),
            child: const Text('Login'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: Gap.sm),
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
              onPressed: () => context.push('/register'),
              child: const Text('Register'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [
            const SizedBox(height: Gap.lg),
            Icon(Icons.auto_stories, size: 64, color: scheme.primary),
            const SizedBox(height: Gap.md),
            Text(
              'BookShelf',
              textAlign: TextAlign.center,
              style: text.headlineLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Gap.sm),
            Text(
              'Your personal library in your pocket. Save the books you own '
              'or want to read, sort them by reading status and genre, and '
              'keep your favorites one tap away.',
              textAlign: TextAlign.center,
              style: text.bodyLarge,
            ),
            const SizedBox(height: Gap.lg),
            for (final (icon, title, body) in _features) ...[
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Gap.md,
                    vertical: Gap.sm,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: Icon(icon),
                  ),
                  title: Text(title, style: text.titleMedium),
                  subtitle: Text(body),
                ),
              ),
              const SizedBox(height: Gap.sm),
            ],
          ],
        ),
      ),
    );
  }
}
