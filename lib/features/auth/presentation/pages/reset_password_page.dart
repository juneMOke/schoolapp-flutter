import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_password_input.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/reset/reset_flow_layout.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/reset/reset_info_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Étape 3 du flux de réinitialisation : choix du nouveau mot de passe, puis
/// reset + auto-login via [AuthBloc]. Validation au flou + soumission façon
/// connexion. Le câblage d'état (reset → unauthenticated → login →
/// authenticated → home) est inchangé.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  String? _passwordError;
  String? _confirmError;

  String? _pendingEmail;
  String? _pendingPassword;
  bool _isWaitingResetResult = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onChanged);
    _confirmPasswordController.addListener(_onChanged);
    _passwordFocus.addListener(_onPasswordBlur);
    _confirmFocus.addListener(_onConfirmBlur);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onChanged);
    _confirmPasswordController.removeListener(_onChanged);
    _passwordFocus.removeListener(_onPasswordBlur);
    _confirmFocus.removeListener(_onConfirmBlur);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _onPasswordBlur() {
    if (!_passwordFocus.hasFocus) {
      setState(() => _passwordError = _validatePassword());
    }
  }

  void _onConfirmBlur() {
    if (!_confirmFocus.hasFocus) {
      setState(() => _confirmError = _validateConfirmation());
    }
  }

  String? _validatePassword() {
    final l10n = AppLocalizations.of(context)!;
    final value = _passwordController.text;
    if (value.isEmpty) return l10n.pleaseEnterPassword;
    if (value.length < 6) return l10n.passwordTooShort;
    return null;
  }

  String? _validateConfirmation() {
    final l10n = AppLocalizations.of(context)!;
    final value = _confirmPasswordController.text;
    if (value.isEmpty) return l10n.pleaseConfirmPassword;
    if (value != _passwordController.text) return l10n.passwordsDoNotMatch;
    return null;
  }

  bool get _canSubmit =>
      _passwordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty;

  void _submit() {
    if (context.read<AuthBloc>().state.status == AuthStatus.loading) {
      return; // anti-doublon
    }

    final passwordError = _validatePassword();
    final confirmError = _validateConfirmation();
    setState(() {
      _passwordError = passwordError;
      _confirmError = confirmError;
    });
    if (passwordError != null) {
      _passwordFocus.requestFocus();
      return;
    }
    if (confirmError != null) {
      _confirmFocus.requestFocus();
      return;
    }

    final forgotState = context.read<ForgotPasswordBloc>().state;
    final email = forgotState.userEmail;
    final token = forgotState.resetToken;
    if (email == null || email.isEmpty || token == null || token.isEmpty) {
      context.goNamed(AppRoutesNames.forgotPasswordEmail);
      return;
    }

    _pendingEmail = email;
    _pendingPassword = _passwordController.text;
    _isWaitingResetResult = true;

    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthResetPasswordRequested(
        email: email,
        newPassword: _passwordController.text,
        otpToken: token,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (_isWaitingResetResult &&
            state.status == AuthStatus.unauthenticated &&
            _pendingEmail != null &&
            _pendingPassword != null) {
          _isWaitingResetResult = false;
          context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _pendingEmail!,
              password: _pendingPassword!,
            ),
          );
          return;
        }

        if (state.status == AuthStatus.authenticated) {
          context.read<ForgotPasswordBloc>().add(
            const ForgotPasswordFlowResetRequested(),
          );
          context.goNamed(AppRoutesNames.home);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.errorMessage != current.errorMessage,
        builder: (context, authState) {
          final forgotState = context.watch<ForgotPasswordBloc>().state;
          final token = forgotState.resetToken;
          final email = forgotState.userEmail;
          final isLoading = authState.status == AuthStatus.loading;
          final l10n = AppLocalizations.of(context)!;

          if (token == null ||
              token.isEmpty ||
              email == null ||
              email.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              context.goNamed(AppRoutesNames.forgotPasswordEmail);
            });
          }

          return ResetFlowLayout(
            currentStep: 3,
            form: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (email != null && email.isNotEmpty) ...[
                  ResetInfoPill(
                    icon: Icons.account_circle_outlined,
                    label: l10n.account(email),
                  ),
                  const SizedBox(height: 18),
                ],
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
                          EteeloPasswordInput(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            label: l10n.newPassword,
                            errorText: _passwordError,
                            onChanged: (_) {
                              if (_passwordError != null) {
                                setState(() => _passwordError = null);
                              }
                            },
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                          ),
                          const SizedBox(height: 16),
                          EteeloPasswordInput(
                            controller: _confirmPasswordController,
                            focusNode: _confirmFocus,
                            label: l10n.confirmPassword,
                            errorText: _confirmError,
                            onChanged: (_) {
                              if (_confirmError != null) {
                                setState(() => _confirmError = null);
                              }
                            },
                            onFieldSubmitted: (_) => _submit(),
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (authState.status == AuthStatus.failure &&
                    authState.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  AuthErrorBanner(message: authState.errorMessage!),
                ],
                const SizedBox(height: 20),
                EteeloButton.primary(
                  onPressed: _canSubmit ? _submit : null,
                  label: l10n.validateAndLogin,
                  isLoading: isLoading,
                  size: EteeloButtonSize.regular,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
