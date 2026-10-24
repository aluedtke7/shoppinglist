import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';

import 'package:shoppinglist/component/dialogs.dart';
import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/component/snackbars.dart';
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

  void _confirmDelete(PocketBaseProvider pbp) {
    showConfirmDialog(
      context,
      i18n(context).p_edit_delete,
      i18n(context).p_edit_delete_q(_originalArticle.article),
    ).then((value) {
      if (value != null && value) {
        pbp.deleteArticle(_originalArticle.id).then((_) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
        pbp.fetchAllArticles();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pbp = context.read<PocketBaseProvider>();
    final scheme = Theme.of(context).colorScheme;
    final canSave = (_isValid ?? false) && !_isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_originalArticle.id.isEmpty ? i18n(context).p_edit_new : i18n(context).p_edit_change),
        actions: [
          if (_originalArticle.id.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton.filledTonal(
                onPressed: () => _confirmDelete(pbp),
                tooltip: i18n(context).p_edit_delete,
                style: IconButton.styleFrom(
                  backgroundColor: scheme.errorContainer,
                  foregroundColor: scheme.error,
                ),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          autovalidateMode: AutovalidateMode.always,
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    child: Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 18,
                          children: [
                            _LabeledField(
                              label: i18n(context).com_shop,
                              child: TextFormField(
                                autofocus: true,
                                initialValue: _shop,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  fillColor: scheme.surface,
                                  prefixIcon: const Icon(Icons.storefront_outlined),
                                ),
                                onSaved: (newValue) => _shop = newValue ?? '',
                              ),
                            ),
                            _LabeledField(
                              label: i18n(context).com_article,
                              child: TextFormField(
                                autofocus: false,
                                initialValue: _articleName,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  fillColor: scheme.surface,
                                  prefixIcon: const Icon(Icons.sell_outlined),
                                  helperText: i18n(context).p_edit_unique_error,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _articleName = value;
                                    _isValid = value.length > 1;
                                  });
                                },
                                onSaved: (newValue) => _articleName = newValue ?? '',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(i18n(context).com_cancel),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: canSave
                            ? () {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  _saveArticle(pbp, context);
                                }
                              }
                            : null,
                        icon: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.check),
                        label: Text(i18n(context).com_save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Field with its label above it instead of a floating label, as in the design.
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
