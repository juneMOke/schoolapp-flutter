import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Qui lira ce qu'on saisit : une ligne discrète sous (ou au-dessus d') un
/// champ. Le portail parent montre aux familles une partie de ce que l'école
/// écrit ; l'agent doit le savoir au moment d'écrire, pas après.
///
/// [public] : visible par les parents (icône d'œil) ; sinon interne à l'école
/// (cadenas).
class AudienceNote extends StatelessWidget {
  final String text;
  final bool public;

  const AudienceNote(this.text, {super.key, this.public = true});

  const AudienceNote.internal(this.text, {super.key}) : public = false;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        public ? Icons.visibility_outlined : Icons.lock_outline,
        size: AppSpacing.lg,
        color: AppColors.textMuted,
      ),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    ],
  );
}
