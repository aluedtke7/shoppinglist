import 'dart:async';

import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:shoppinglist/component/article_selection_card.dart';
import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/component/recipe_card.dart';
import 'package:shoppinglist/component/snackbars.dart';
import 'package:shoppinglist/model/article.dart';
import 'package:shoppinglist/model/recipe.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';
import 'package:shoppinglist/view/article_edit_page.dart';

Future<bool?> showConfirmDialog(BuildContext context, String title, String message) async {
  var noText = i18n(context).com_no;
  var yesText = i18n(context).com_yes;
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
          child: Text(noText),
        ),
        ElevatedButton(
          autofocus: false,
          onPressed: () {
            Navigator.of(ctx).pop(true);
          },
          child: Text(yesText),
        ),
      ],
    ),
  );
}

/// Confirmation dialog for destructive actions. Cancel + red Delete buttons.
/// Returns true if the user confirmed the deletion.
Future<bool?> showDeleteConfirmDialog(BuildContext context, String title, String message) async {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(i18n(context).com_cancel),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(i18n(context).com_delete),
        ),
      ],
    ),
  );
}

Future<bool?> showEndShoppingDialog(BuildContext context, PocketBaseProvider pbp) async {
  return showConfirmDialog(context, i18n(context).drawer_end_shopping, i18n(context).drawer_end_shopping_q)
      .then((value) {
    if (value != null && value) {
      pbp.endShopping();
    }
    return false;
  });
}

Future<String?> showSettingsDialog(BuildContext context, String title, String info, String initVal) async {
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

Future<String?> showInputDialog(BuildContext context, String title, String message, String initValue) async {
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

Future<Recipe?> selectRecipeDialog(BuildContext context, PocketBaseProvider pbp) async {
  return showDialog<Recipe>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(i18n(context).p_recipes_select),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, minWidth: 400, maxHeight: 400),
          child: ListView.builder(
            shrinkWrap: true,
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

Future<Article?> searchForArticle(BuildContext context, PocketBaseProvider pbp,
    {bool dontAdd = false, bool showAll = false}) async {
  Timer? delayedSearch;
  var textController = TextEditingController();
  var textField = TextField(
    decoration: InputDecoration(
      hintText: i18n(context).com_search_term,
      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      prefixIcon: const Icon(Icons.search),
    ),
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
              showErrorSnackbar(context, e);
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
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            actionsPadding: const EdgeInsets.all(20),
            title: Text(
              i18n(context).p_active_tooltip,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            // Ground color, so the white search field and result card stand out as on the pages.
            backgroundColor: Theme.of(context).colorScheme.surface,
            actionsAlignment: MainAxisAlignment.spaceBetween,
            content: SizedBox(
              width: isMobile ? double.maxFinite : mq.size.width * 0.7,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  textField,
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (context, idx) {
                        return ArticleSelectionCard(
                          article: pbp.searchArticles[idx],
                          isFirst: idx == 0,
                          isLast: idx == pbp.searchArticles.length - 1,
                        );
                      },
                      separatorBuilder: (context, idx) => ColoredBox(
                        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                        child: const Divider(indent: 16, endIndent: 16),
                      ),
                      itemCount: pbp.searchArticles.length,
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              OutlinedButton(
                autofocus: false,
                onPressed: () {
                  Navigator.of(ctx).pop(null);
                },
                child: Text(i18n(context).com_back),
              ),
              Text(
                i18n(context).com_num_articles(pbp.searchArticles.length),
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
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
                    icon: const Icon(Icons.add),
                    label: Text(i18n(context).com_new)),
            ],
          ),
        );
      });
}
