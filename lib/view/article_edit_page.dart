import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:theme_provider/theme_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final pbp = Provider.of<PocketBaseProvider>(context, listen: false);
    final article = ModalRoute.of(context)!.settings.arguments as Article;
    _isValid ??= article.article.length > 1;

    var appBar = AppBar(
      title: Text(
          article.id.isEmpty ? AppLocalizations.of(context)!.p_edit_new : AppLocalizations.of(context)!.p_edit_change),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_rounded),
          onPressed: (article.id.isEmpty)
              ? null
              : () {
                  Statics.showConfirmDialog(
                    context,
                    AppLocalizations.of(context)!.p_edit_delete,
                    AppLocalizations.of(context)!.p_edit_delete_q(article.article),
                  ).then((value) {
                    if (value != null && value) {
                      pbp.deleteArticle(article.id).then((_) => Navigator.of(context).pop());
                      pbp.fetchAllArticles();
                      pbp.fetchActive();
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
                    setState(() {
                      _isLoading = true;
                    });
                    pbp.updateArticle(article).then((_) {
                      pbp.fetchAllArticles();
                      pbp.fetchActive();
                      Navigator.of(context).pop();
                    }).catchError((e) {
                      if (e is ClientException) {
                        Statics.showErrorSnackbar(context, e);
                      }
                    }).whenComplete(() {
                      setState(() {
                        _isLoading = false;
                      });
                    });
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
                                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.com_shop),
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
                                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.com_article),
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
