import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:shoppinglist/component/statics.dart';
import 'package:shoppinglist/component/theme_options.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';
import 'package:shoppinglist/view/active_page.dart';
import 'package:shoppinglist/view/article_page.dart';
import 'package:shoppinglist/view/login_page.dart';

class SlappDrawer extends StatelessWidget {
  const SlappDrawer({Key? key}) : super(key: key);

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
                    AppLocalizations.of(context)!.drawer_title,
                    textScaleFactor: 1.6,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      pbp.userName,
                      textScaleFactor: 1.2,
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
                          return Text(AppLocalizations.of(context)!.drawer_version(defText));
                        }),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.p_active_title),
              selected: ModalRoute.of(context)?.settings.name == ActivePage.routeName,
              onTap: () {
                Navigator.pushNamed(context, ActivePage.routeName);
              },
              leading: const Icon(
                Icons.list,
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.p_articles_title),
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
              title: Text(AppLocalizations.of(context)!.drawer_end_shopping),
              onTap: () {
                Statics.showConfirmDialog(context, AppLocalizations.of(context)!.drawer_end_shopping,
                        AppLocalizations.of(context)!.drawer_end_shopping_q)
                    .then((value) {
                  if (value != null && value) {
                    pbp.endShopping();
                    Navigator.pop(context);
                  }
                });
              },
              leading: const Icon(
                Icons.shopping_bag_outlined,
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(AppLocalizations.of(context)!.drawer_logout),
              onTap: () {
                Statics.showConfirmDialog(context, AppLocalizations.of(context)!.drawer_logout,
                        AppLocalizations.of(context)!.drawer_logout_q)
                    .then((value) {
                  if (value != null && value) {
                    pbp.logout();
                    Navigator.pushNamedAndRemoveUntil(context, LoginPage.routeName, (route) => false);
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
