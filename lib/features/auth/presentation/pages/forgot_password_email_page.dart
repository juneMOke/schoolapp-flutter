import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_email_input.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/reset/reset_flow_layout.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Étape 1 du flux de réinitialisation : saisie de l'e-mail recevant le code.
/// Validation au flou + à la soumission (jamais à la frappe), façon connexion.
class ForgotPasswordEmailPage extends StatefulWidget {
  const ForgotPasswordEmailPage({super.key});

  @override
  State<ForgotPasswordEmailPage> createState() =>
      _ForgotPasswordEmailPageState();
}

class _ForgotPasswordEmailPageState extends State<ForgotPasswordEmailPage> {
  static final _emailRegex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');

  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onChanged);
    _emailFocus.addListener(_onEmailBlur);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onChanged);
    _emailFocus.removeListener(_onEmailBlur);
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _onEmailBlur() {
    if (!_emailFocus.hasFocus) {
      setState(() => _emailError = _validateEmail());
    }
  }

  String? _validateEmail() {
    final l10n = AppLocalizations.of(context)!;
    final value = _emailController.text.trim();
    if (value.isEmpty) return l10n.loginEmailRequired;
    if (!_emailRegex.hasMatch(value)) return l10n.loginEmailInvalid;
    return null;
  }

  bool get _canSubmit => _emailController.text.trim().isNotEmpty;

  void _submit() {
    if (context.read<ForgotPasswordBloc>().state.status ==
        ForgotPasswordStatus.loading) {
      return; // anti-doublon
    }

    final emailError = _validateEmail();
    setState(() => _emailError = emailError);
    if (emailError != null) {
      _emailFocus.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();
    context.read<ForgotPasswordBloc>().add(
      ForgotPasswordGenerateOtpRequested(
        userEmail: _emailController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ForgotPasswordStatus.otpGenerated) {
          context.goNamed(AppRoutesNames.forgotPasswordOtp);
        }
      },
      child: BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.errorMessage != current.errorMessage,
        builder: (context, state) {
          final isLoading = state.status == ForgotPasswordStatus.loading;
          final l10n = AppLocalizations.of(context)!;

          return ResetFlowLayout(
            currentStep: 1,
            form: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                IgnorePointer(
                  ignoring: isLoading,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: isLoading ? 0.6 : 1,
                    child: AutofillGroup(
                      child: EteeloEmailInput(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        label: l10n.loginEmailLabel,
                        errorText: _emailError,
                        onChanged: (_) {
                          if (_emailError != null) {
                            setState(() => _emailError = null);
                          }
                        },
                        textInputAction: TextInputAction.done,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                      ),
                    ),
                  ),
                ),
                if (state.status == ForgotPasswordStatus.failure &&
                    state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  AuthErrorBanner(message: state.errorMessage!),
                ],
                const SizedBox(height: 20),
                EteeloButton.primary(
                  onPressed: _canSubmit ? _submit : null,
                  label: l10n.sendCode,
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
