import 'dart:async';

import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:shoppinglist/component/article_selection_card.dart';
import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/component/recipe_card.dart';
import 'package:shoppinglist/model/article.dart';
import 'package:shoppinglist/model/recipe.dart';
import 'package:shoppinglist/model/pref_keys.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';
import 'package:shoppinglist/view/article_edit_page.dart';

class Statics {
  static Future<void> showErrorSnackbar(BuildContext ctx, dynamic e) async {
    final String msg;
    if (e is ClientException) {
      String? errMsg = e.originalError?.toString();
      errMsg ??= e.response.entries.firstWhere((element) => element.key == 'message').value;
      msg = 'Error\nServer ${e.url?.host}\n$errMsg';
    } else {
      msg = e.toString();
    }

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(ctx).colorScheme.error,
        content: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(milliseconds: 5000),
        padding: const EdgeInsets.all(8.0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
    );
  }

  static Future<void> showInfoSnackbar(BuildContext ctx, dynamic e) async {
    final String msg = e.toString();

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(ctx).colorScheme.primary,
        content: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(ctx).cardTheme.color)),
        duration: const Duration(milliseconds: 3000),
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
      color: const Color.fromARGB(255, 200, 200, 200).withValues(alpha: 0.9),
    );
  }

  static BoxDecoration getGradientPageDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          const Color.fromARGB(255, 230, 230, 230).withValues(alpha: 0.5),
          const Color.fromARGB(255, 152, 152, 152).withValues(alpha: 0.9),
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

  static Color getSlideBtnForegroundLight(BuildContext ctx) {
    return Theme.of(ctx).colorScheme.onPrimary.withAlpha(200);
  }

  static Color getSlideBtnBackgroundDark(BuildContext ctx) {
    return Theme.of(ctx).colorScheme.secondary.withAlpha(200);
  }

  static Color getSlideBtnForegroundDark(BuildContext ctx) {
    return Theme.of(ctx).colorScheme.onSecondary.withAlpha(200);
  }

  static BoxDecoration getGradientDrawerDecoration(BuildContext ctx) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          ThemeProvider.controllerOf(ctx).theme.data.colorScheme.surface.withValues(alpha: .1),
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
      color: ThemeProvider.controllerOf(ctx).theme.data.colorScheme.surface.withValues(alpha: .1),
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
            child: Text(i18n(context).com_no),
          ),
          ElevatedButton(
            autofocus: false,
            onPressed: () {
              Navigator.of(ctx).pop(true);
            },
            child: Text(i18n(context).com_yes),
          ),
        ],
      ),
    );
  }

  static Future<bool?> showEndShoppingDialog(BuildContext context, PocketBaseProvider pbp) async {
    return showConfirmDialog(context, i18n(context).drawer_end_shopping, i18n(context).drawer_end_shopping_q)
        .then((value) {
      if (value != null && value) {
        pbp.endShopping();
      }
      return false;
    });
  }

  static Future<String?> showSettingsDialog(BuildContext context, String title, String info, String initVal) async {
    var input = initVal;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController textEditingController = TextEditingController(text: initVal);
    // the url ValidationBuilder accepts no localhost as valid url, so we have to allow that separately
    final validator = ValidationBuilder(localeName: Intl.defaultLocale)
        .or((builder) => builder.regExp(RegExp('^http[s]?://localhost'), 'No valid localhost url'),
            (builder) => builder.url())
        .required()
        .build();

    return showDialog<String?>(
      context: context,
      builder: (ctx) {
        var textFormField = TextFormField(
          autofocus: true,
          controller: textEditingController,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: i18n(context).l_p_server_example,
            errorText: validator(input),
          ),
          keyboardType: TextInputType.url,
          validator: validator,
          onChanged: (value) => input = value,
          onFieldSubmitted: (value) {
            // debugPrint('onFieldSubmitted: $value');
            // debugPrint('Validation: ${validator(value)}');
            if (formKey.currentState?.validate() ?? false) {
              Navigator.of(ctx).pop(value);
            }
          },
        );
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info),
                    const SizedBox(height: 16),
                    textFormField,
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                autofocus: false,
                onPressed: () {
                  Navigator.of(ctx).pop(null);
                },
                child: Text(i18n(context).com_cancel),
              ),
              ElevatedButton(
                autofocus: false,
                onPressed: () {
                  Navigator.of(ctx).pop(input);
                },
                child: Text(i18n(context).com_save),
              ),
            ],
          );
        });
      },
    );
  }

  static Future<String?> showInputDialog(BuildContext context, String title, String message, String initValue) async {
    var input = initValue;

    return showDialog<String?>(
      context: context,
      builder: (ctx) {
        var textFormField = TextFormField(
          initialValue: initValue,
          decoration: InputDecoration(
            labelText: i18n(context).l_p_email,
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) => input = value,
        );
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text(message),
                textFormField,
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              autofocus: true,
              onPressed: () {
                Navigator.of(ctx).pop(null);
              },
              child: Text(i18n(context).com_cancel),
            ),
            ElevatedButton(
              autofocus: false,
              onPressed: () {
                Navigator.of(ctx).pop(input);
              },
              child: Text(i18n(context).l_p_reset_password),
            ),
          ],
        );
      },
    );
  }

  static Future<Recipe?> selectRecipeDialog(BuildContext context, PocketBaseProvider pbp) async {
    return showDialog<Recipe>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(i18n(context).p_recipes_select),
          content: SizedBox(
            width: 400,
            height: 400,
            child: ListView.builder(
              itemCount: pbp.allRecipes.length,
              itemBuilder: (c, i) {
                final r = pbp.allRecipes[i];
                final count = pbp.recipeArticleCount[r.id] ?? 0;
                return RecipeCard(
                  recipe: r,
                  articleCount: count,
                  onTap: () => Navigator.of(c).pop(r),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(i18n(context).com_cancel),
            )
          ],
        );
      },
    );
  }

  static Future<Article?> searchForArticle(BuildContext context, PocketBaseProvider pbp,
      {bool dontAdd = false, bool showAll = false}) async {
    Timer? delayedSearch;
    var textController = TextEditingController();
    var textField = TextField(
      decoration: InputDecoration(labelText: i18n(context).com_search_term),
      autofocus: true,
      controller: textController,
      onChanged: (text) {
        delayedSearch?.cancel();
        delayedSearch = Timer(const Duration(milliseconds: 750), () {
          if (text.length < 3) {
            pbp.clearSearchList();
          } else {
            pbp.searchForArticles(text, showAll).catchError((e) {
              if (e is ClientException && context.mounted) {
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
          final mq = MediaQuery.of(ctx);
          final isMobile = mq.size.width < 600;
          return Scaffold(
            backgroundColor: const Color.fromARGB(0, 0, 0, 0),
            body: AlertDialog(
              insetPadding:
                  isMobile ? const EdgeInsets.all(8) : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
              titlePadding: const EdgeInsets.only(left: 12, right: 12, top: 12),
              contentPadding: const EdgeInsets.only(left: 12, right: 12),
              actionsPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              title: Text(i18n(context).p_active_tooltip),
              backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
              actionsAlignment: MainAxisAlignment.spaceBetween,
              content: SizedBox(
                width: isMobile ? double.maxFinite : mq.size.width * 0.7,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                ElevatedButton(
                  autofocus: false,
                  onPressed: () {
                    Navigator.of(ctx).pop(null);
                  },
                  child: Text(i18n(context).com_back),
                ),
                Text(i18n(context).com_num_articles(pbp.searchArticles.length)),
                if (!dontAdd)
                  ElevatedButton.icon(
                      onPressed: textController.text.isNotEmpty
                          ? () {
                              Navigator.pushReplacementNamed(context, ArticleEditPage.routeName,
                                  arguments: Article(
                                    active: !dontAdd,
                                    amount: 1,
                                    article: textController.text,
                                  ));
                            }
                          : null,
                      icon: const Icon(Icons.add_sharp),
                      label: Text(i18n(context).com_new)),
              ],
            ),
          );
        });
  }

  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final debugUrl = const String.fromEnvironment('SHOPPINGLIST_HOST', defaultValue: '');
    return debugUrl.isNotEmpty ? debugUrl : prefs.getString(PrefKeys.serverUrlPrefsKey) ?? '';
  }
}
