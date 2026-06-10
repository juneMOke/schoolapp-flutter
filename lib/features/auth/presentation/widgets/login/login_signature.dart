import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Signature éditoriale Lora italique qui clôt le formulaire (spec COMPOSANT 05).
/// « eteyelo · l'école en lingala » — rappelle l'origine lingala du nom.
class LoginSignature extends StatelessWidget {
  const LoginSignature({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Text(
      l10n.loginSignature,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Lora',
        fontSize: 13,
        fontStyle: FontStyle.italic,
        color: AppColors.textMuted,
      ),
    );
  }
}
