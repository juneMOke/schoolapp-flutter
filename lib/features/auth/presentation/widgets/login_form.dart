import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/widgets/eteelo_email_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_password_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_validation_button.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;
        final l10n = AppLocalizations.of(context)!;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              EteeloEmailInput(
                controller: _emailController,
                label: l10n.email,
                validator: (value) => validateEmail(context, value),
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              EteeloPasswordInput(
                controller: _passwordController,
                label: l10n.password,
                validator: (value) => validatePassword(context, value),
                enabled: !isLoading,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              if (state.status == AuthStatus.failure &&
                  state.errorMessage != null) ...[
                AuthErrorBanner(message: state.errorMessage!),
                const SizedBox(height: 12),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          context.read<ForgotPasswordBloc>().add(
                            const ForgotPasswordFlowResetRequested(),
                          );
                          context.goNamed(AppRoutesNames.forgotPasswordEmail);
                        },
                  icon: const Icon(Icons.help_outline_rounded, size: 14),
                  label: Text(l10n.forgotPassword),
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
                  ),
                ),
              ),
              const SizedBox(height: 8),
              EteeloValidationButton(
                onPressed: _submit,
                label: l10n.signIn,
                isLoading: isLoading,
              ),
            ],
          ),
        );
      },
    );
  }

  String? validatePassword(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterPassword;
    }
    if (value.length < 6) {
      return l10n.passwordTooShort;
    }
    return null;
  }

  String? validateEmail(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return l10n.pleaseEnterEmail;
    }
    if (!value.contains('@')) {
      return l10n.pleaseEnterValidEmail;
    }
    return null;
  }
}