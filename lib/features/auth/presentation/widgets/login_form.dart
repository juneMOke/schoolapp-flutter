import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/branding/auth/auth_form_header.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_email_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_password_input.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/login/login_banner_data.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/login/login_error_banner.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/login/login_signature.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';
import 'package:url_launcher/url_launcher.dart';

/// Panneau formulaire de l'écran de connexion (spec Connexion §02–08).
/// Validation au flou + à la soumission (jamais à la frappe), états de
/// soumission verrouillés, bandeaux d'erreur typés au-dessus du bouton.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  static final _emailRegex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    // Bouton « désactivé tant qu'un requis est vide » (spec §04) → on suit la
    // saisie pour réévaluer l'état d'activation.
    _emailController.addListener(_onChanged);
    _passwordController.addListener(_onChanged);
    // Validation au flou (spec §06) : on valide quand le champ perd le focus.
    _emailFocus.addListener(_onEmailBlur);
    _passwordFocus.addListener(_onPasswordBlur);
  }

  @override
  void dispose() {
    // Retrait des listeners avant dispose : éviter un setState déclenché par la
    // perte de focus pendant la destruction du FocusNode.
    _emailController.removeListener(_onChanged);
    _passwordController.removeListener(_onChanged);
    _emailFocus.removeListener(_onEmailBlur);
    _passwordFocus.removeListener(_onPasswordBlur);
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _onEmailBlur() {
    if (!_emailFocus.hasFocus) {
      setState(() => _emailError = _validateEmail());
    }
  }

  void _onPasswordBlur() {
    if (!_passwordFocus.hasFocus) {
      setState(() => _passwordError = _validatePassword());
    }
  }

  String? _validateEmail() {
    final l10n = AppLocalizations.of(context)!;
    final value = _emailController.text.trim();
    if (value.isEmpty) return l10n.loginEmailRequired;
    if (!_emailRegex.hasMatch(value)) return l10n.loginEmailInvalid;
    return null;
  }

  String? _validatePassword() {
    final l10n = AppLocalizations.of(context)!;
    if (_passwordController.text.isEmpty) return l10n.loginPasswordRequired;
    return null;
  }

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  void _submit() {
    final state = context.read<AuthBloc>().state;
    if (state.status == AuthStatus.loading) return; // anti-doublon

    final emailError = _validateEmail();
    final passwordError = _validatePassword();
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });

    // Le premier champ en erreur reçoit le focus (spec §06).
    if (emailError != null) {
      _emailFocus.requestFocus();
      return;
    }
    if (passwordError != null) {
      _passwordFocus.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _onForgotPassword() {
    context.read<ForgotPasswordBloc>().add(
      const ForgotPasswordFlowResetRequested(),
    );
    context.goNamed(AppRoutesNames.forgotPasswordEmail);
  }

  // Point de branchement 403 « Compte désactivé » (spec §08) — dormant tant que
  // le backend n'émet pas ce signal.
  Future<void> _onContactAdmin() async {
    final uri = Uri(scheme: 'mailto');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorKind != current.errorKind,
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;
        final l10n = AppLocalizations.of(context)!;

        return FocusTraversalGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthFormHeader(
                eyebrow: l10n.loginEyebrow,
                title: l10n.login,
                subtitle: l10n.loginSubtitle,
              ),
              const SizedBox(height: 20),
              // Champs verrouillés pendant la soumission (opacité 0.6, spec §07).
              IgnorePointer(
                ignoring: isLoading,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: isLoading ? 0.6 : 1,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EteeloEmailInput(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          label: l10n.loginEmailLabel,
                          errorText: _emailError,
                          onChanged: (_) {
                            if (_emailError != null) {
                              setState(() => _emailError = null);
                            }
                          },
                          textInputAction: TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.username,
                            AutofillHints.email,
                          ],
                        ),
                        const SizedBox(height: 16),
                        EteeloPasswordInput(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          label: l10n.password,
                          errorText: _passwordError,
                          onChanged: (_) {
                            if (_passwordError != null) {
                              setState(() => _passwordError = null);
                            }
                          },
                          onFieldSubmitted: (_) => _submit(),
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading ? null : _onForgotPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 44),
                  ),
                  child: Text(l10n.forgotPassword),
                ),
              ),
              if (state.status == AuthStatus.failure) ...[
                const SizedBox(height: 4),
                LoginErrorBanner(
                  data: LoginBannerData.fromErrorKind(
                    state.errorKind ?? AuthErrorKind.generic,
                    l10n: l10n,
                    onRetry: _submit,
                    onContactAdmin: _onContactAdmin,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              EteeloButton.primary(
                onPressed: _canSubmit ? _submit : null,
                label: l10n.signIn,
                icon: Icons.login_rounded,
                isLoading: isLoading,
                loadingLabel: l10n.loginSubmitting,
                size: EteeloButtonSize.regular,
              ),
              const SizedBox(height: 32),
              const LoginSignature(),
            ],
          ),
        );
      },
    );
  }
}
