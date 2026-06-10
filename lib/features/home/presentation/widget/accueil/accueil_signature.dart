import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_ui_tokens.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Signature de marque — clôture éditoriale de la page (spec Accueil §05).
///
/// Décoratif : exclu de l'ordre de tabulation et du lecteur d'écran. La copy
/// lingala n'est jamais traduite (clé identique FR/EN).
class AccueilSignature extends StatelessWidget {
  const AccueilSignature({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ExcludeSemantics(
      child: Text(
        l10n.accueilSignature,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Lora',
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w400,
          fontSize: AccueilUiTokens.signatureFontSize,
          height: AccueilUiTokens.signatureHeight,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
