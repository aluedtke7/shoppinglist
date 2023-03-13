import 'dart:async';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:shoppinglist/component/article_selection_card.dart';
import 'package:shoppinglist/model/article.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';
import 'package:shoppinglist/view/article_edit_page.dart';

class Statics {
  static Future<void> showErrorSnackbar(BuildContext ctx, dynamic e) async {
    final String msg;
    if (e is ClientException) {
      msg = 'Error\nServer ${e.url?.host}\n${e.originalError}';
    } else {
      msg = e.toString();
    }

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(ctx).colorScheme.error,
        content: Text(msg, style: TextStyle(color: Theme.of(ctx).colorScheme.onErrorContainer)),
        duration: const Duration(milliseconds: 5000),
        padding: const EdgeInsets.all(8.0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
    );
  }

  static BoxDecoration getSimplePageDecoration() {
    return BoxDecoration(
      color: const Color.fromARGB(255, 200, 200, 200).withOpacity(0.9),
    );
  }

  static BoxDecoration getGradientPageDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          const Color.fromARGB(255, 230, 230, 230).withOpacity(0.5),
          const Color.fromARGB(255, 152, 152, 152).withOpacity(0.9),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0, 1],
      ),
    );
  }

  static Color getSlideBtnBackgroundLight(BuildContext ctx) {
    return Theme.of(ctx).colorScheme.primary.withAlpha(200);
  }

  static Color getSlideBtnBackgroundDark(BuildContext ctx) {
    return Theme.of(ctx).colorScheme.secondary.withAlpha(200);
  }

  static BoxDecoration getGradientDrawerDecoration(BuildContext ctx) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          // const Color.fromARGB(255, 250, 250, 250).withOpacity(0.5),
          // const Color.fromARGB(255, 200, 200, 200).withOpacity(0.9),
          ThemeProvider.controllerOf(ctx).theme.data.colorScheme.surface.withOpacity(.1),
          ThemeProvider.controllerOf(ctx).theme.data.colorScheme.onSurfaceVariant.withAlpha(100),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0, 1],
      ),
    );
  }

  static BoxDecoration getSimpleDrawerDecoration(BuildContext ctx) {
    return BoxDecoration(
      color: ThemeProvider.controllerOf(ctx).theme.data.colorScheme.surface.withOpacity(.1),
    );
  }

  static BoxDecoration getGradientDrawerHeaderDecoration(BuildContext ctx) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          ThemeProvider.controllerOf(ctx).theme.data.colorScheme.primary,
          ThemeProvider.controllerOf(ctx).theme.data.colorScheme.primary.withAlpha(100),
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        stops: const [0, 1],
      ),
    );
  }

  static BoxDecoration getSimpleDrawerHeaderDecoration(BuildContext ctx) {
    return BoxDecoration(
      color: ThemeProvider.controllerOf(ctx).theme.data.colorScheme.primary,
      // ThemeProvider.controllerOf(ctx).theme.data.colorScheme.primary.withAlpha(100),
    );
  }

  static Future<bool?> showConfirmDialog(BuildContext context, String title, String message) async {
    return showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          ElevatedButton(
            autofocus: true,
            onPressed: () {
              Navigator.of(ctx).pop(false);
            },
            child: Text(AppLocalizations.of(context)!.com_no),
          ),
          ElevatedButton(
            autofocus: false,
            onPressed: () {
              Navigator.of(ctx).pop(true);
            },
            child: Text(AppLocalizations.of(context)!.com_yes),
          ),
        ],
      ),
    );
  }

  static Future<Article?> searchForArticle(BuildContext context, PocketBaseProvider pbp) async {
    Timer? delayedSearch;
    var textController = TextEditingController();
    var textField = TextField(
      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.com_search_term),
      autofocus: true,
      controller: textController,
      onChanged: (text) {
        delayedSearch?.cancel();
        delayedSearch = Timer(const Duration(milliseconds: 750), () {
          if (text.length < 3) {
            pbp.clearSearchList();
          } else {
            pbp.searchForArticles(text).catchError((e) {
              if (e is ClientException) {
                Statics.showErrorSnackbar(context, e);
              }
            });
          }
        });
      },
    );

    return showDialog<Article?>(
      context: context,
      builder: (ctx) {
        return Scaffold(
          backgroundColor: const Color.fromARGB(0, 0, 0, 0),
          body: AlertDialog(
            title: Text(AppLocalizations.of(context)!.p_active_tooltip),
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            actionsAlignment: MainAxisAlignment.spaceBetween,
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  textField,
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemBuilder: (context, idx) {
                        return ArticleSelectionCard(
                          article: pbp.searchArticles[idx],
                        );
                      },
                      itemCount: pbp.searchArticles.length,
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              IconButton(
                onPressed: textController.text.isNotEmpty
                    ? () {
                        Navigator.pushReplacementNamed(context, ArticleEditPage.routeName,
                            arguments: Article(
                              active: true,
                              amount: 1,
                              article: textController.text,
                            ));
                      }
                    : null,
                icon: const Icon(Icons.add_sharp),
              ),
              Text(AppLocalizations.of(context)!.com_num_articles(pbp.searchArticles.length)),
              ElevatedButton(
                autofocus: false,
                onPressed: () {
                  Navigator.of(ctx).pop(null);
                },
                child: Text(AppLocalizations.of(context)!.com_back),
              ),
            ],
          ),
        );
      },
    );
  }
}
