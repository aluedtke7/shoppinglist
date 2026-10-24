import 'package:flutter/material.dart';

import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/view/active_page.dart';
import 'package:shoppinglist/view/article_page.dart';
import 'package:shoppinglist/view/recipe_page.dart';

/// Bottom navigation between the three main pages; replaces the former drawer.
class SlappNavigationBar extends StatelessWidget {
  const SlappNavigationBar({super.key, required this.selectedIndex});

  final int selectedIndex;

  static const _routeNames = [ActivePage.routeName, ArticlePage.routeName, RecipePage.routeName];

  static Widget _buildPage(int index) => switch (index) {
        0 => const ActivePage(),
        1 => const ArticlePage(),
        _ => const RecipePage(),
      };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == selectedIndex) return;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              settings: RouteSettings(name: _routeNames[index]),
              pageBuilder: (context, animation, secondaryAnimation) => _buildPage(index),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.shopping_cart_outlined),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: i18n(context).nav_active,
          ),
          NavigationDestination(
            icon: const Icon(Icons.format_list_bulleted),
            label: i18n(context).nav_articles,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: i18n(context).nav_recipes,
          ),
        ],
      ),
    );
  }
}
