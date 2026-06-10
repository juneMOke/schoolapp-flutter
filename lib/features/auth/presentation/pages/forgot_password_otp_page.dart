import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_otp_input.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/reset/reset_flow_layout.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/reset/reset_info_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Étape 2 du flux de réinitialisation : saisie du code OTP reçu par e-mail.
/// Conserve `Form`+`validator` (l'OTP n'expose pas d'errorText manuel).
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
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.userEmail != current.userEmail ||
            previous.errorMessage != current.errorMessage,
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

          return ResetFlowLayout(
            currentStep: 2,
            form: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (email != null && email.isNotEmpty) ...[
                    ResetInfoPill(
                      icon: Icons.mark_email_unread_outlined,
                      label: l10n.codeSentTo(email),
                    ),
                    const SizedBox(height: 18),
                  ],
                  EteeloOtpInput(
                    controller: _otpController,
                    label: l10n.otpCodeLabel,
                    enabled: !isLoading,
                    validator: (value) => _validateOtp(context, value),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (state.status == ForgotPasswordStatus.failure &&
                      state.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    AuthErrorBanner(message: state.errorMessage!),
                  ],
                  const SizedBox(height: 20),
                  EteeloButton.primary(
                    onPressed: _submit,
                    label: l10n.validateCode,
                    isLoading: isLoading,
                    size: EteeloButtonSize.regular,
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
