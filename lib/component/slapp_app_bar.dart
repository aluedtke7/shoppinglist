import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/component/slapp_menu_sheet.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';

class SlappAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SlappAppBar({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final pbp = context.watch<PocketBaseProvider>();
    final scheme = Theme.of(context).colorScheme;
    final initial = pbp.isAuth && pbp.userName.isNotEmpty ? pbp.userName.characters.first.toUpperCase() : '';

    return AppBar(
      toolbarHeight: 64,
      titleSpacing: 20,
      title: Text(
        title,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      ),
      actions: [
        if (!pbp.isHealthy)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(Icons.cloud_off, color: scheme.error),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton.filledTonal(
            onPressed: () => showSlappMenu(context),
            tooltip: i18n(context).com_menu,
            style: IconButton.styleFrom(
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.primary,
              fixedSize: const Size(44, 44),
            ),
            icon: initial.isEmpty
                ? const Icon(Icons.person_outline)
                : Text(
                    initial,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: scheme.primary),
                  ),
          ),
        ),
      ],
    );
  }
}
