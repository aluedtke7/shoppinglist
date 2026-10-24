import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoppinglist/component/dialogs.dart';
import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/component/selected_page.dart';
import 'package:shoppinglist/component/slapp_app_bar.dart';
import 'package:shoppinglist/component/snackbars.dart';
import 'package:shoppinglist/model/pref_keys.dart';
import 'package:shoppinglist/model/sel_page.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';
import 'package:shoppinglist/service/biometric_auth_service.dart';
import 'package:shoppinglist/service/config_service.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    page = SelPage.login;

    return const Scaffold(
      // Keeps the menu (color scheme, language, server) reachable before login.
      appBar: SlappAppBar(title: ''),
      body: SafeArea(child: _LoginCard()),
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
  final BiometricAuthService _biometric = BiometricAuthService();
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
    _biometric.stop();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _initBiometricLogin() async {
    await _loadPrefs();
    final supported = await _biometric.isSupported();
    if (!mounted) return;
    setState(() {
      _canUseBiometric = supported;
    });
    if (_canUseBiometric &&
        _savedPassword.isNotEmpty &&
        _email.isNotEmpty &&
        !_biometricAttempted &&
        !_globalBiometricInProgress) {
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

  Future<void> _loadPrefs() async {
    final url = await getServerUrl();
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
      final authenticated = await _biometric.authenticate(
        reason: biometricReason,
        title: biometricTitle,
        cancelButton: cancelButton,
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
            showErrorSnackbar(context, error);
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
        showErrorSnackbar(context, e);
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
          showErrorSnackbar(context, error);
        }
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setServerUrl(String value) {
    setState(() {
      _serverUrl = value;
    });
    _savePrefs();
  }

  @override
  Widget build(BuildContext context) {
    final showBiometricButton = _canUseBiometric && _savedPassword.isNotEmpty && _email.isNotEmpty;

    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Logo(),
                        const SizedBox(height: 20),
                        Text(
                          i18n(context).l_p_login,
                          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          i18n(context).l_p_login_info,
                          style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 40),
                        _buildEmailField(context),
                        const SizedBox(height: 16),
                        _buildPasswordField(context),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: _serverUrl.isEmpty ? const SizedBox(height: 16) : _ForgotPasswordButton(email: _email),
                        ),
                        _buildSubmitRow(context, showBiometricButton: showBiometricButton),
                        const Spacer(),
                        const SizedBox(height: 40),
                        _ServerCard(serverUrl: _serverUrl, onUrlSet: _setServerUrl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField(BuildContext context) {
    return TextFormField(
      autofillHints: const [AutofillHints.email],
      controller: _emailController,
      focusNode: _emailFocus,
      autofocus: !_canUseBiometric || _savedPassword.isEmpty,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: i18n(context).l_p_email,
        prefixIcon: const Icon(Icons.mail_outline),
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
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return TextFormField(
      autofillHints: const [AutofillHints.password],
      controller: _passwordController,
      focusNode: _passwordFocus,
      autofocus: !_canUseBiometric || _savedPassword.isEmpty,
      obscureText: _hidePW,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: i18n(context).l_p_password,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _hidePW = !_hidePW;
            });
          },
          icon: _hidePW ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility),
        ),
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
    );
  }

  Widget _buildSubmitRow(BuildContext context, {required bool showBiometricButton}) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _serverUrl.isEmpty ? null : () => _submit(),
            child: Text(i18n(context).l_p_login_btn),
          ),
        ),
        if (showBiometricButton)
          IconButton.filledTonal(
            onPressed: _authenticateWithBiometric,
            tooltip: i18n(context).l_p_biometric_tooltip,
            style: IconButton.styleFrom(
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.primary,
              fixedSize: const Size(56, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.fingerprint, size: 28),
          ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.shopping_cart_outlined, size: 32, color: scheme.onPrimary),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFF4C04A),
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({required this.serverUrl, required this.onUrlSet});

  final String serverUrl;
  final ValueChanged<String> onUrlSet;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.dns_outlined, size: 20, color: scheme.onSurfaceVariant),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  'PocketBase Server',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
                ),
                Text(
                  serverUrl.isEmpty ? i18n(context).l_p_server_url_not_set : serverUrl,
                  maxLines: serverUrl.isEmpty ? null : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: serverUrl.isEmpty ? scheme.error : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              showSettingsDialog(
                context,
                i18n(context).l_p_server_url,
                i18n(context).l_p_server_url_info,
                serverUrl,
              ).then((value) {
                if (value != null && value.isNotEmpty) {
                  onUrlSet(value);
                }
              });
            },
            child: Text(i18n(context).com_edit),
          ),
        ],
      ),
    );
  }
}

class _ForgotPasswordButton extends StatelessWidget {
  const _ForgotPasswordButton({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        showInputDialog(
          context,
          i18n(context).l_p_forgot_password,
          i18n(context).l_p_forgot_password_info,
          email,
        ).then((value) {
          if (value != null && value.isNotEmpty && context.mounted) {
            Provider.of<PocketBaseProvider>(context, listen: false).sendPasswordResetEmail(value).then((_) {
              if (context.mounted) {
                return showInfoSnackbar(context, i18n(context).l_p_email_sent);
              }
            }).onError((error, stackTrace) {
              if (context.mounted) {
                return showErrorSnackbar(context, error);
              }
            });
          }
        });
      },
      child: Text(i18n(context).l_p_forgot_password),
    );
  }
}
