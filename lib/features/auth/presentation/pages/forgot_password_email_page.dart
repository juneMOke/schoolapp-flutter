import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/widgets/eteelo_email_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_validation_button.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/app_title.dart';
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
                    final l10n = AppLocalizations.of(context)!;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        EteeloAppTitle(subTitle: l10n.enterEmailToReceiveOtp),
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  EteeloEmailInput(
                                    controller: _emailController,
                                    label: l10n.email,
                                    validator: (value) =>
                                        _validateEmail(context, value),
                                    enabled: !isLoading,
                                  ),
                                  const SizedBox(height: 16),
                                  if (state.status ==
                                          ForgotPasswordStatus.failure &&
                                      state.errorMessage != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Text(
                                        state.errorMessage!,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  EteeloValidationButton(
                                    onPressed: _submit,
                                    label: l10n.sendCode,
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
