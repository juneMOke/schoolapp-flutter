import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/auth_flow_shell.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/login_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthFlowShell(
      title: l10n.login,
      subtitle: l10n.signInToContinue,
      icon: Icons.lock_person_rounded,
      showBackButton: false,
      child: const LoginForm(),
    );
  }
}
