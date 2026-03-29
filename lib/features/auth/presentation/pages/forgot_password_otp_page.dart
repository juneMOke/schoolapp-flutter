import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/app_title.dart';
import 'package:school_app_flutter/core/widgets/eteelo_otp_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_validation_button.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/forgot_password_bloc.dart';
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
                child: BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
                  builder: (context, state) {
                    final isLoading =
                        state.status == ForgotPasswordStatus.loading;
                    final email = state.userEmail;
                    final l10n = AppLocalizations.of(context)!;

                    if (email == null || email.isEmpty) {
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
                          subTitle: email == null ? '' : l10n.codeSentTo(email),
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
                                  EteeloOtpInput(
                                    controller: _otpController,
                                    label: l10n.otpCodeLabel,
                                    enabled: !isLoading,
                                    validator: (value) => _validateOtp(context, value),
                                    onFieldSubmitted: (_) => _submit(),
                                  ),
                                  const SizedBox(height: 16),
                                  if (state.status == ForgotPasswordStatus.failure &&
                                      state.errorMessage != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Text(
                                        state.errorMessage!,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.error,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  EteeloValidationButton(
                                    onPressed: _submit,
                                    label: l10n.validateCode,
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

  String? _validateOtp(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context)!;
    final otp = value?.trim() ?? '';
    if (otp.length != 6) {
      return l10n.otpMustBeSixDigits;
    }
    return null;
  }
}
