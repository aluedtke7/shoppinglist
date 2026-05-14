import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:shoppinglist/component/dialogs.dart';
import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/component/snackbars.dart';
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

  late String _shop;
  late String _articleName;
  late Article _originalArticle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _originalArticle = ModalRoute.of(context)!.settings.arguments as Article;
    _shop = _originalArticle.shop;
    _articleName = _originalArticle.article;
    _isValid ??= _articleName.length > 1;
  }

  void _saveArticle(PocketBaseProvider pbp, BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final updatedArticle = _originalArticle.copyWith(
        shop: _shop,
        article: _articleName,
      );
      await pbp.updateArticle(updatedArticle);
      pbp.fetchAllArticles();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (err) {
      if (err is ClientException && err.response['data']?['article']?['code'] == 'validation_not_unique') {
        if (context.mounted) {
          showErrorSnackbar(context, i18n(context).p_edit_unique_error);
        }
      } else {
        if (context.mounted) {
          showErrorSnackbar(context, err);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pbp = context.read<PocketBaseProvider>();

    var appBar = AppBar(
      title: Text(_originalArticle.id.isEmpty ? i18n(context).p_edit_new : i18n(context).p_edit_change),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_rounded),
          onPressed: (_originalArticle.id.isEmpty)
              ? null
              : () {
                  showConfirmDialog(
                    context,
                    i18n(context).p_edit_delete,
                    i18n(context).p_edit_delete_q(_originalArticle.article),
                  ).then((value) {
                    if (value != null && value) {
                      pbp.deleteArticle(_originalArticle.id).then((_) {
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
                    _saveArticle(pbp, context);
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
                                initialValue: _shop,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(labelText: i18n(context).com_shop),
                                onSaved: (newValue) => _shop = newValue ?? '',
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: TextFormField(
                                autofocus: false,
                                initialValue: _articleName,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(labelText: i18n(context).com_article),
                                onChanged: (value) {
                                  setState(() {
                                    _articleName = value;
                                    _isValid = value.length > 1;
                                  });
                                },
                                onSaved: (newValue) => _articleName = newValue ?? '',
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
