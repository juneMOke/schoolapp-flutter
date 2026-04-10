import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/widgets/eteelo_email_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_validation_button.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/auth_flow_shell.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class ForgotPasswordEmailPage extends StatefulWidget {
  const ForgotPasswordEmailPage({super.key});

  @override
  State<ForgotPasswordEmailPage> createState() =>
      _ForgotPasswordEmailPageState();
}

class _ForgotPasswordEmailPageState extends State<ForgotPasswordEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

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
        builder: (context, state) {
          final isLoading = state.status == ForgotPasswordStatus.loading;
          final l10n = AppLocalizations.of(context)!;

          return AuthFlowShell(
            title: l10n.forgotPasswordTitle,
            subtitle: l10n.enterEmailToReceiveOtp,
            icon: Icons.mark_email_read_outlined,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  EteeloEmailInput(
                    controller: _emailController,
                    label: l10n.email,
                    validator: (value) => _validateEmail(context, value),
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),
                  if (state.status == ForgotPasswordStatus.failure &&
                      state.errorMessage != null) ...[
                    AuthErrorBanner(message: state.errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  EteeloValidationButton(
                    onPressed: _submit,
                    label: l10n.sendCode,
                    isLoading: isLoading,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String? _validateEmail(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return l10n.pleaseEnterEmail;
    }
    if (!email.contains('@')) {
      return l10n.pleaseEnterValidEmail;
    }
    return null;
  }
}