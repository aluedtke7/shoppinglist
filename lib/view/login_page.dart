import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/component/selected_page.dart';
import 'package:shoppinglist/component/slapp_app_bar.dart';
import 'package:shoppinglist/component/statics.dart';
import 'package:shoppinglist/component/theme_options.dart';
import 'package:shoppinglist/model/pref_keys.dart';
import 'package:shoppinglist/model/sel_page.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';
import 'package:theme_provider/theme_provider.dart';

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
  static bool _globalBiometricInProgress = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  var _hidePW = true;
  var _email = '';
  var _password = '';
  var _isLoading = false;
  var _serverUrl = '';
  var _savedPassword = '';
  var _canUseBiometric = false;
  var _biometricAttempted = false;

  @override
  void initState() {
    super.initState();
    // Reset global flag and local flag when returning to login page (after logout)
    _globalBiometricInProgress = false;
    _biometricAttempted = false;
    _initBiometricLogin();
  }

  @override
  void dispose() {
    try {
      _localAuth.stopAuthentication();
    } catch (_) {
      // Ignore errors during dispose
    }
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _initBiometricLogin() async {
    await _loadPrefs();
    await _checkBiometric();
    if (mounted && _canUseBiometric && _savedPassword.isNotEmpty && _email.isNotEmpty && !_biometricAttempted && !_globalBiometricInProgress) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted && !_isLoading && !_biometricAttempted && !_globalBiometricInProgress) {
          // Small delay to ensure UI is fully rendered (helps on Android after logout)
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted && !_isLoading && !_biometricAttempted && !_globalBiometricInProgress) {
            _authenticateWithBiometric();
          }
        }
      });
    }
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Future<void> _checkBiometric() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _canUseBiometric = canAuthenticate && isDeviceSupported;
      });
    } catch (_) {
      setState(() {
        _canUseBiometric = false;
      });
    }
  }

  Future<void> _loadPrefs() async {
    final url = await Statics.getServerUrl();
    var savedEmail = await _secureStorage.read(key: PrefKeys.lastEmailSecureKey) ?? '';
    var savedPassword = await _secureStorage.read(key: PrefKeys.lastPasswordSecureKey) ?? '';
    setState(() {
      _serverUrl = url;
      _email = savedEmail;
      _savedPassword = savedPassword;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(PrefKeys.serverUrlPrefsKey, _serverUrl);
    if (_email.isNotEmpty) {
      await _secureStorage.write(key: PrefKeys.lastEmailSecureKey, value: _email);
    }
    if (_password.isNotEmpty) {
      await _secureStorage.write(key: PrefKeys.lastPasswordSecureKey, value: _password);
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (!mounted || !_canUseBiometric || _savedPassword.isEmpty || _email.isEmpty || _isLoading) {
      return;
    }

    // Prevent concurrent authentication attempts globally
    if (_globalBiometricInProgress || _biometricAttempted) {
      return;
    }
    _biometricAttempted = true;
    _globalBiometricInProgress = true;

    // Capture context-dependent values before async gap
    final biometricReason = i18n(context).l_p_biometric_reason;
    final biometricTitle = i18n(context).l_p_biometric_title;
    final cancelButton = i18n(context).com_cancel;
    final pbProvider = Provider.of<PocketBaseProvider>(context, listen: false);

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: biometricReason,
        biometricOnly: true,
        authMessages: <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: biometricTitle,
            signInHint: '',
            cancelButton: cancelButton,
          ),
          IOSAuthMessages(
            localizedFallbackTitle: biometricTitle,
            cancelButton: cancelButton,
          ),
        ],
      );

      if (!mounted) return;

      if (authenticated) {
        setState(() {
          _isLoading = true;
        });
        try {
          await pbProvider.login(_email, _savedPassword);
          // Success - don't reset flag so it never shows again this session
        } on ClientException catch (error) {
          if (mounted) {
            Statics.showErrorSnackbar(context, error);
          }
          _globalBiometricInProgress = false;
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } on LocalAuthException catch (_) {
      // User canceled or system canceled - allow retry
      _biometricAttempted = false;
      _globalBiometricInProgress = false;
    } on PlatformException catch (e) {
      _biometricAttempted = false;
      _globalBiometricInProgress = false;
      if (mounted) {
        Statics.showErrorSnackbar(context, e);
      }
    }
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
                            if (_canUseBiometric && _savedPassword.isNotEmpty && _email.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: IconButton(
                                  icon: const Icon(Icons.fingerprint, size: 32),
                                  onPressed: _authenticateWithBiometric,
                                  tooltip: i18n(context).l_p_biometric_tooltip,
                                ),
                              ),
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
                                  autofocus: !_canUseBiometric || _savedPassword.isEmpty,
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
                                child: _hidePW ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility),
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
                                  autofocus: !_canUseBiometric || _savedPassword.isEmpty,
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
                                  onPressed: _serverUrl.isEmpty ? null : () => _submit(),
                                  child: Text(i18n(context).l_p_login_btn),
                                ),
                              ),
                            ],
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _serverUrl.isEmpty
                                  ? Column(
                                      spacing: 12,
                                      children: [
                                        Text(
                                          i18n(context).l_p_server_url_not_set,
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Statics.showSettingsDialog(
                                              context,
                                              i18n(context).l_p_server_url,
                                              i18n(context).l_p_server_url_info,
                                              '',
                                            ).then((value) {
                                              if (value != null && value.isNotEmpty) {
                                                setState(() {
                                                  _serverUrl = value;
                                                });
                                                _savePrefs();
                                              }
                                            });
                                          },
                                          child: Text(
                                            i18n(context).l_p_server_url_configure,
                                          ),
                                        ),
                                      ],
                                    )
                                  : TextButton(
                                      onPressed: () {
                                        Statics.showInputDialog(
                                          context,
                                          i18n(context).l_p_forgot_password,
                                          i18n(context).l_p_forgot_password_info,
                                          _email,
                                        ).then((value) {
                                          if (value != null && value.isNotEmpty && context.mounted) {
                                            Provider.of<PocketBaseProvider>(context, listen: false)
                                                .sendPasswordResetEmail(value)
                                                .then((value) {
                                              if (context.mounted) {
                                                return Statics.showInfoSnackbar(context, i18n(context).l_p_email_sent);
                                              }
                                            }).onError((error, stackTrace) {
                                              if (context.mounted) {
                                                return Statics.showErrorSnackbar(context, error);
                                              }
                                            });
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
