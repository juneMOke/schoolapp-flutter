import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/app_title.dart';
import 'package:school_app_flutter/core/widgets/eteelo_password_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_validation_button.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _pendingEmail;
  String? _pendingPassword;
  bool _isWaitingResetResult = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
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
          return;
        }

        if (state.status == AuthStatus.failure && state.errorMessage != null) {
          _isWaitingResetResult = false;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.indigo),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    final forgotState = context
                        .watch<ForgotPasswordBloc>()
                        .state;
                    final token = forgotState.resetToken;
                    final email = forgotState.userEmail;
                    final isLoading = authState.status == AuthStatus.loading;
                    final l10n = AppLocalizations.of(context)!;

                    if (token == null ||
                        token.isEmpty ||
                        email == null ||
                        email.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!context.mounted) {
                          return;
                        }
                        context.goNamed(AppRoutesNames.forgotPasswordEmail);
                      });
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        EteeloAppTitle(
                          subTitle: email == null ? '' : l10n.account(email),
                        ),
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  EteeloPasswordInput(
                                    controller: _passwordController,
                                    label: l10n.newPassword,
                                    enabled: !isLoading,
                                    validator: (value) => _validatePassword(context, value),
                                  ),
                                  const SizedBox(height: 16),
                                  EteeloPasswordInput(
                                    controller: _confirmPasswordController,
                                    label: l10n.confirmPassword,
                                    enabled: !isLoading,
                                    validator: (value) => _validatePasswordConfirmation(context, value),
                                    onFieldSubmitted: (_) => _submit(),
                                  ),
                                  const SizedBox(height: 24),
                                  EteeloValidationButton(
                                    onPressed: _submit,
                                    label: l10n.validateAndLogin,
                                    isLoading: isLoading,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validatePassword(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterPassword;
    }
    if (value.length < 6) {
      return l10n.passwordTooShort;
    }
    return null;
  }

  String? _validatePasswordConfirmation(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.pleaseConfirmPassword;
    }
    if (value != _passwordController.text) {
      return l10n.passwordsDoNotMatch;
    }
    return null;
  }
}
