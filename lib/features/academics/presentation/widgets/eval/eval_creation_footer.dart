import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ligne d'aide, sous le formulaire de création : une icône, un texte muet.
class EvalCreationHint extends StatelessWidget {
  final String text;

  const EvalCreationHint(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 1),
        child: Icon(
          Icons.info_outline_rounded,
          size: 15,
          color: AppColors.textMuted,
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          text,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
      ),
    ],
  );
}

/// Pied de la modale (spec §5) : « Annuler » | « Créer l'évaluation ».
class EvalCreationActions extends StatelessWidget {
  final bool inProgress;

  /// `null` : bouton principal désactivé (formulaire incomplet, cible fermée).
  final VoidCallback? onSubmit;

  const EvalCreationActions({
    super.key,
    required this.inProgress,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: EteeloButton.secondary(
            label: l10n.evalCreateCancel,
            size: EteeloButtonSize.regular,
            onPressed: inProgress ? null : () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          // Gel READ_ONLY (ADR-010) : la modale peut être ouverte au moment où
          // le tick de fraîcheur bascule le mode — le submit doit être gaté
          // comme le FAB d'entrée.
          child: SessionWriteGate(
            child: EteeloButton.primary(
              label: l10n.evalCreateSubmit,
              icon: Icons.check_rounded,
              isLoading: inProgress,
              size: EteeloButtonSize.regular,
              onPressed: inProgress ? null : onSubmit,
            ),
          ),
        ),
      ],
    );
  }
}
