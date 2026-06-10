import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/branding/auth/auth_brand_content.dart';
import 'package:school_app_flutter/core/branding/auth/auth_shell_layout.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/login_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Écran de connexion ETEELO CONNECT (spec Connexion). Verrou éditorial à deux
/// panneaux responsive — la mise en page et le panneau de marque sont portés par
/// la charte partagée [AuthShellLayout] ; le contenu du formulaire par
/// [LoginForm].
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthShellLayout(
      form: const LoginForm(),
      brand: AuthBrandContent(
        title: l10n.loginBrandTitle,
        condensedTitle: l10n.loginBrandTitleCondensed,
        highlight: l10n.loginBrandTitleHighlight,
        subtitle: l10n.loginBrandSubtitle,
      ),
    );
  }
}
