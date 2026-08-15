import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le dernier cycle de **lecture** n'a pas tout ramené (ADR-015 F1).
///
/// Vit au-dessus du corps de la feuille, jamais dedans : le corps est piloté à
/// 100 % par l'outbox et bascule sur « Aucune écriture en échec » dès qu'elle
/// est vide. Une dégradation de lecture posée là serait avalée par cet état
/// vide, et l'utilisateur lirait le contraire de ce qu'on veut lui dire.
///
/// **L'action dépend de la cause, et elle seule.** Un droit manquant ne se
/// réessaie pas : le flux est sauté à chaque cycle, et offrir « Réessayer »
/// serait le même mensonge que celui que ce lot corrige ailleurs — un geste qui
/// promet de lever une condition qu'il ne touche pas. Un échec de transport, en
/// revanche, se réessaie très bien, et sans ce bouton il n'existerait aucun
/// moyen de le faire : le pull n'a que deux déclencheurs, l'ouverture de session
/// et le retour de la radio, et une tablette en Wi-Fi permanent n'en verra
/// aucun de la journée.
///
/// Pas de rouge dans les deux cas : ce n'est pas un échec d'écriture, et un
/// compte au périmètre étroit est dans cet état en permanence.
class SyncIncompleteReadBand extends StatelessWidget {
  /// Le cycle a échoué sur au moins une ressource — un transport, pas un droit.
  /// Seul ce cas mérite un bouton, cf. la docstring de la classe.
  final bool retriable;

  /// Déclenche un nouveau cycle. `null` ⇒ aucun bouton, quelle que soit
  /// [retriable] — la feuille montée sans cubit (galerie, test) reste muette
  /// plutôt que d'offrir une action morte.
  final VoidCallback? onRetry;

  const SyncIncompleteReadBand({
    super.key,
    this.retriable = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final retry = onRetry;
    final showRetry = retriable && retry != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cloud_done_outlined,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.syncIncompleteReadTitle,
                  style: AppTypography.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  showRetry
                      ? l10n.syncIncompleteReadRetriableDescription
                      : l10n.syncIncompleteReadDescription,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (showRetry) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        // Largeur bornée : sans `minimumSize`, le thème
                        // plein-largeur fait exploser un bouton inline.
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(
                            0,
                            AppDimensions.minTouchTarget,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                        ),
                        onPressed: retry,
                        child: Text(l10n.syncIncompleteReadRetry),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
