import 'package:flutter/material.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/component/statics.dart';
import 'package:shoppinglist/component/theme_options.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';
import 'package:shoppinglist/view/active_page.dart';
import 'package:shoppinglist/view/article_page.dart';
import 'package:shoppinglist/view/login_page.dart';

class SlappDrawer extends StatelessWidget {
  const SlappDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final pbp = context.read<PocketBaseProvider>();

    return Drawer(
      child: Container(
        decoration: ThemeProvider.optionsOf<ThemeOptions>(context).drawerDecoration(context),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: ThemeProvider.optionsOf<ThemeOptions>(context).drawerHeaderDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i18n(context).drawer_title,
                    textScaler: const TextScaler.linear(1.6),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      pbp.userName,
                      textScaler: const TextScaler.linear(1.2),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (ctx, snapshot) {
                          var defText = '---';
                          if (snapshot.hasData) {
                            defText = '${snapshot.data!.version}+${snapshot.data!.buildNumber}';
                          }
                          return Text(
                            i18n(context).drawer_version(defText),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          );
                        }),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(i18n(context).p_active_title),
              selected: ModalRoute.of(context)?.settings.name == ActivePage.routeName,
              onTap: () {
                Navigator.pushNamed(context, ActivePage.routeName);
              },
              leading: const Icon(
                Icons.list,
              ),
            ),
            ListTile(
              title: Text(i18n(context).p_articles_title),
              selected: ModalRoute.of(context)?.settings.name == ArticlePage.routeName,
              onTap: () {
                Navigator.pushNamed(context, ArticlePage.routeName);
              },
              leading: const Icon(
                Icons.list,
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(i18n(context).drawer_end_shopping),
              onTap: () {
                Statics.showEndShoppingDialog(context, pbp).then((b) {
                  if (context.mounted) Navigator.pop(context);
                });
              },
              leading: ImageIcon(
                size: 24,
                AssetImage('assets/race_flag.png'),
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(i18n(context).drawer_logout),
              onTap: () {
                Statics.showConfirmDialog(context, i18n(context).drawer_logout, i18n(context).drawer_logout_q)
                    .then((value) {
                  if (value != null && value) {
                    pbp.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, LoginPage.routeName, (route) => false);
                    }
                  }
                });
              },
              leading: const Icon(
                Icons.logout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
