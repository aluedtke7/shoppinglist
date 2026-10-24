import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:shoppinglist/application.dart';
import 'package:shoppinglist/component/dialogs.dart';
import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/model/pref_keys.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';
import 'package:shoppinglist/service/config_service.dart';
import 'package:shoppinglist/view/login_page.dart';

Future<void> showSlappMenu(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    useSafeArea: true,
    builder: (_) => const SlappMenuSheet(),
  );
}

/// Bottom sheet with the user, settings and logout; replaces the former drawer.
class SlappMenuSheet extends StatelessWidget {
  const SlappMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final pbp = context.watch<PocketBaseProvider>();
    final scheme = Theme.of(context).colorScheme;
    final language = Localizations.localeOf(context).languageCode == 'de' ? 'Deutsch' : 'English';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (pbp.isAuth) ...[
              _UserHeader(userName: pbp.userName),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await showEndShoppingDialog(context, pbp);
                  if (context.mounted) Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.primary,
                  minimumSize: const Size.fromHeight(60),
                  alignment: AlignmentDirectional.centerStart,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  textStyle:
                      Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                icon: const ImageIcon(AssetImage('assets/race_flag.png'), size: 22),
                label: Text(i18n(context).drawer_end_shopping),
              ),
              const SizedBox(height: 8),
            ],
            _MenuTile(
              icon: Icons.palette_outlined,
              title: i18n(context).com_change_theme,
              onTap: () => ThemeProvider.controllerOf(context).nextTheme(),
            ),
            _MenuTile(
              icon: Icons.language,
              title: i18n(context).com_change_language,
              trailing: Text(language, style: TextStyle(color: scheme.onSurfaceVariant)),
              onTap: _toggleLanguage,
            ),
            _MenuTile(
              icon: Icons.dns_outlined,
              title: i18n(context).com_change_server,
              onTap: () => _changeServerUrl(context, pbp),
            ),
            if (pbp.isAuth) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Divider(),
              ),
              _MenuTile(
                icon: Icons.logout,
                title: i18n(context).drawer_logout,
                color: scheme.error,
                onTap: () => _logout(context, pbp),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleLanguage() {
    if ((Intl.defaultLocale ?? '').contains('de')) {
      Intl.defaultLocale = 'en';
      APPLIC().onLocaleChanged(const Locale('en', ''));
    } else {
      Intl.defaultLocale = 'de';
      APPLIC().onLocaleChanged(const Locale('de', ''));
    }
  }

  Future<void> _changeServerUrl(BuildContext context, PocketBaseProvider pbp) async {
    final serverUrl = await getServerUrl();
    if (!context.mounted) return;
    final value = await showSettingsDialog(
      context,
      i18n(context).l_p_server_url,
      i18n(context).l_p_server_url_info,
      serverUrl,
    );
    if (value != null && value.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PrefKeys.serverUrlPrefsKey, value);
      pbp.setPocketBaseUrl(value);
    }
  }

  Future<void> _logout(BuildContext context, PocketBaseProvider pbp) async {
    final value = await showConfirmDialog(context, i18n(context).drawer_logout, i18n(context).drawer_logout_q);
    if (value != null && value) {
      pbp.logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, LoginPage.routeName, (route) => false);
      }
    }
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 18),
      child: Row(
        spacing: 14,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            child: Text(
              userName.isEmpty ? '?' : userName.characters.first.toUpperCase(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(userName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (ctx, snapshot) {
                    var version = '---';
                    if (snapshot.hasData) {
                      version = '${snapshot.data!.version}+${snapshot.data!.buildNumber}';
                    }
                    return Text(
                      '${i18n(context).drawer_title} · ${i18n(context).drawer_version(version)}',
                      style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.color,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      minTileHeight: 56,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      iconColor: color ?? scheme.onSurfaceVariant,
      textColor: color ?? scheme.onSurface,
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      trailing: trailing ?? (color == null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}
