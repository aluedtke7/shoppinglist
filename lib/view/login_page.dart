import 'package:email_validator/email_validator.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/component/selected_page.dart';
import 'package:shoppinglist/component/slapp_app_bar.dart';
import 'package:shoppinglist/component/statics.dart';
import 'package:shoppinglist/component/theme_options.dart';
import 'package:shoppinglist/model/pref_keys.dart';
import 'package:shoppinglist/model/sel_page.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    page = SelPage.login;

    return Scaffold(
      appBar: const SlappAppBar(title: 'Shoppinglist'),
      body: Stack(
        children: [
          Container(
            decoration: ThemeProvider.optionsOf<ThemeOptions>(context).pageDecoration,
          ),
          const _LoginCard(),
        ],
      ),
    );
  }
}

class _LoginCard extends StatefulWidget {
  const _LoginCard();

  @override
  _LoginCardState createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  var _hidePW = true;
  var _email = '';
  var _password = '';
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _email = prefs.getString(PrefKeys.lastUserPrefsKey) ?? '';
      _emailController.text = _email;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(PrefKeys.lastUserPrefsKey, _email);
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });
      try {
        // try to authenticate the user...
        await Provider.of<PocketBaseProvider>(context, listen: false).login(_email, _password);
        _savePrefs();
      } on ClientException catch (error) {
        if (mounted) {
          Statics.showErrorSnackbar(context, error);
        }
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(top: mq.viewInsets.bottom > 0 ? 0 : 50),
          child: Center(
            child: Container(
              width: 340,
              height: mq.viewInsets.bottom > 0 ? mq.size.height - 200 - mq.viewInsets.bottom : null,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.all(Radius.circular(15)),
              ),
              child: Form(
                autovalidateMode: null,
                key: _formKey,
                child: SingleChildScrollView(
                  child: AutofillGroup(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                              child: Text(
                                i18n(context).l_p_login,
                                textScaler: const TextScaler.linear(2),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        Row(
                          children: [
                            const SizedBox(
                              width: 50,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.email),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: SizedBox(
                                width: 240,
                                child: TextFormField(
                                  autofillHints: const [AutofillHints.email],
                                  controller: _emailController,
                                  focusNode: _emailFocus,
                                  autofocus: true,
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: i18n(context).l_p_email,
                                  ),
                                  validator: (value) {
                                    if (EmailValidator.validate(value!)) {
                                      return null;
                                    }
                                    return i18n(context).l_p_email_val;
                                  },
                                  onFieldSubmitted: (value) {
                                    _emailFocus.unfocus();
                                    FocusScope.of(context).requestFocus(_passwordFocus);
                                  },
                                  onSaved: (newValue) => _email = newValue ?? '',
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _hidePW = !_hidePW;
                                });
                              },
                              child: SizedBox(
                                width: 50,
                                child: _hidePW
                                    ? const Icon(Icons.visibility_off)
                                    : const Icon(Icons.visibility),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 16, bottom: 8),
                              child: SizedBox(
                                width: 240,
                                child: TextFormField(
                                  autofillHints: const [AutofillHints.password],
                                  controller: _passwordController,
                                  focusNode: _passwordFocus,
                                  autofocus: true,
                                  obscureText: _hidePW,
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    labelText: i18n(context).l_p_password,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return i18n(context).l_p_password_val;
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (value) {
                                    _submit();
                                  },
                                  onEditingComplete: () => TextInput.finishAutofillContext(),
                                  onSaved: (newValue) => _password = newValue ?? '',
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_isLoading)
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 34, 16),
                                child: ElevatedButton(
                                  child: Text(i18n(context).l_p_login_btn),
                                  onPressed: () {
                                    _submit();
                                  },
                                ),
                              ),
                            ],
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextButton(
                                  onPressed: () {
                                    Statics.showInputDialog(
                                      context,
                                      i18n(context).l_p_forgot_password,
                                      i18n(context).l_p_forgot_password_info,
                                      _email,
                                    ).then((value) {
                                      if (value != null && value.isNotEmpty) {
                                        Provider.of<PocketBaseProvider>(context, listen: false)
                                            .sendPasswordResetEmail(value)
                                            .then((value) => Statics.showInfoSnackbar(
                                                context, i18n(context).l_p_email_sent))
                                            .onError((error, stackTrace) =>
                                                Statics.showErrorSnackbar(context, error));
                                      }
                                    });
                                  },
                                  child: Text(i18n(context).l_p_forgot_password)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
