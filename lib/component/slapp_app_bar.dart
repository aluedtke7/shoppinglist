import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:shoppinglist/application.dart';
import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';

import 'package:theme_provider/theme_provider.dart';

class SlappAppBar extends StatefulWidget implements PreferredSizeWidget {
  const SlappAppBar({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<SlappAppBar> createState() => _SlappAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SlappAppBarState extends State<SlappAppBar> {
  @override
  Widget build(BuildContext context) {
    final pbp = Provider.of<PocketBaseProvider>(context, listen: true);

    return AppBar(
      iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
      backgroundColor: Theme.of(context).colorScheme.primary,
      title: Text(
        widget.title,
        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
      ),
      actions: [
        if (!pbp.isHealthy)
          const Padding(
            padding: EdgeInsets.only(right: 32),
            child: Icon(Icons.cloud_off),
          ),
        IconButton(
          onPressed: () {
            ThemeProvider.controllerOf(context).nextTheme();
          },
          icon: const Icon(Icons.color_lens),
          tooltip: i18n(context).com_change_theme,
        ),
        IconButton(
          onPressed: () {
            if ((Intl.defaultLocale ?? '').contains('de')) {
              Intl.defaultLocale = 'en';
              APPLIC().onLocaleChanged(const Locale('en', ''));
            } else {
              Intl.defaultLocale = 'de';
              APPLIC().onLocaleChanged(const Locale('de', ''));
            }
          },
          icon: const Icon(Icons.language),
          tooltip: i18n(context).com_change_language,
        )
      ],
    );
  }
}
