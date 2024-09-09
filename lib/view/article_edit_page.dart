import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/component/statics.dart';
import 'package:shoppinglist/component/theme_options.dart';
import 'package:shoppinglist/model/article.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';

class ArticleEditPage extends StatefulWidget {
  const ArticleEditPage({super.key});

  static const routeName = '/articleEdit';

  @override
  State<ArticleEditPage> createState() => _ArticleEditPageState();
}

class _ArticleEditPageState extends State<ArticleEditPage> {
  var _isLoading = false;
  bool? _isValid;
  final _formKey = GlobalKey<FormState>();

  void copyArticle(PocketBaseProvider pbp, Article article, BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await pbp.updateArticle(article);
      pbp.fetchAllArticles();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (err) {
      if (err is ClientException && err.response['data']?['article']?['code'] == 'validation_not_unique') {
        if (context.mounted) {
          Statics.showErrorSnackbar(context, i18n(context).p_edit_unique_error);
        }
      } else {
        if (context.mounted) {
          Statics.showErrorSnackbar(context, err);
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pbp = Provider.of<PocketBaseProvider>(context, listen: false);
    final article = ModalRoute.of(context)!.settings.arguments as Article;
    _isValid ??= article.article.length > 1;

    var appBar = AppBar(
      title: Text(article.id.isEmpty ? i18n(context).p_edit_new : i18n(context).p_edit_change),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_rounded),
          onPressed: (article.id.isEmpty)
              ? null
              : () {
                  Statics.showConfirmDialog(
                    context,
                    i18n(context).p_edit_delete,
                    i18n(context).p_edit_delete_q(article.article),
                  ).then((value) {
                    if (value != null && value) {
                      pbp.deleteArticle(article.id).then((_) {
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      });
                      pbp.fetchAllArticles();
                    }
                  });
                },
        ),
        IconButton(
          icon: const Icon(Icons.save_rounded),
          onPressed: (!(_isValid ?? false))
              ? null
              : () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    copyArticle(pbp, article, context);
                  }
                },
        ),
      ],
    );

    return Scaffold(
      appBar: appBar,
      body: Container(
        decoration: ThemeProvider.optionsOf<ThemeOptions>(context).pageDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  height: null,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                  ),
                  child: Form(
                      autovalidateMode: AutovalidateMode.always,
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: TextFormField(
                                autofocus: true,
                                initialValue: article.shop,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(labelText: i18n(context).com_shop),
                                onSaved: (newValue) => article.shop = newValue ?? '',
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: TextFormField(
                                autofocus: false,
                                initialValue: article.article,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(labelText: i18n(context).com_article),
                                onChanged: (value) {
                                  setState(() {
                                    _isValid = value.length > 1;
                                  });
                                },
                                onSaved: (newValue) => article.article = newValue ?? '',
                              ),
                            ),
                            if (_isLoading) const CircularProgressIndicator(),
                          ],
                        ),
                      )),
                )),
          ],
        ),
      ),
    );
  }
}
