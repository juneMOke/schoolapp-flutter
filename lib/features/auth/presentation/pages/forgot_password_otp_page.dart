import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/widgets/eteelo_otp_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_validation_button.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/auth_flow_shell.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class ForgotPasswordOtpPage extends StatefulWidget {
  const ForgotPasswordOtpPage({super.key});

  @override
  State<ForgotPasswordOtpPage> createState() => _ForgotPasswordOtpPageState();
}

class _ForgotPasswordOtpPageState extends State<ForgotPasswordOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final forgotState = context.read<ForgotPasswordBloc>().state;
    final email = forgotState.userEmail;
    if (email == null || email.isEmpty) {
      context.goNamed(AppRoutesNames.forgotPasswordEmail);
      return;
    }

    context.read<ForgotPasswordBloc>().add(
      ForgotPasswordValidateOtpRequested(
        userEmail: email,
        code: _otpController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ForgotPasswordStatus.otpValidated) {
          context.goNamed(AppRoutesNames.forgotPasswordReset);
        }
      },
      child: BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
        builder: (context, state) {
          final isLoading = state.status == ForgotPasswordStatus.loading;
          final email = state.userEmail;
          final l10n = AppLocalizations.of(context)!;

          if (email == null || email.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              context.goNamed(AppRoutesNames.forgotPasswordEmail);
            });
          }

          return AuthFlowShell(
            title: l10n.otpValidation,
            subtitle: l10n.enterSixDigitCode,
            icon: Icons.password_rounded,
            topAccessory: email == null || email.isEmpty
                ? null
                : AuthInfoPill(
                    icon: Icons.mark_email_unread_outlined,
                    label: l10n.codeSentTo(email),
                  ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  EteeloOtpInput(
                    controller: _otpController,
                    label: l10n.otpCodeLabel,
                    helperText: l10n.enterSixDigitCode,
                    enabled: !isLoading,
                    validator: (value) => _validateOtp(context, value),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),
                  if (state.status == ForgotPasswordStatus.failure &&
                      state.errorMessage != null) ...[
                    AuthErrorBanner(message: state.errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  EteeloValidationButton(
                    onPressed: _submit,
                    label: l10n.validateCode,
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

  String? _validateOtp(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    final otp = value?.trim() ?? '';
    if (otp.length != 6) {
      return l10n.otpMustBeSixDigits;
    }
    return null;
  }
}