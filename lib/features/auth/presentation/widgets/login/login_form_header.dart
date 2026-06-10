import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// En-tête du panneau formulaire (spec §ANATOMIE 4) : eyebrow « Espace
/// direction », titre « Connexion » (h1 sémantique), sous-texte.
class LoginFormHeader extends StatelessWidget {
  const LoginFormHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.loginEyebrow.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.3,
            color: AppColors.terreCuite,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(
            l10n.login,
            style: const TextStyle(
              fontFamily: 'Lora',
              fontSize: 26,
              fontWeight: FontWeight.w600,
              height: 1.1,
              color: AppColors.bleuProfond,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.loginSubtitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
