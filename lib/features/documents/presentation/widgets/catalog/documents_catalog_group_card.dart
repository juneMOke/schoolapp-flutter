import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_catalog_entry.dart';
import 'package:school_app_flutter/features/documents/presentation/context/documents_catalog_intent.dart';
import 'package:school_app_flutter/features/documents/presentation/models/documents_catalog_action.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/catalog/documents_catalog_labels.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/catalog/documents_catalog_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Carte d'un groupe du catalogue (§06) : médaillon, titre, sous-titre, puis
/// une ligne par pièce du groupe.
///
/// La carte est **toujours affichée**, même si l'élève n'a encore rien reçu :
/// c'est le catalogue des documents **possibles**, pas la liste de ceux qui
/// existent. C'est ce qui rend inutile toute section « archive » séparée.
class DocumentsCatalogGroupCard extends StatelessWidget {
  final EditiqueCatalogGroup group;
  final DocumentsCatalogIntent intent;

  /// Résout l'action d'une pièce. Injectée par la page, qui seule connaît les
  /// gardes (éligibilité, connectivité, axe de synchro du dossier).
  final DocumentsCatalogAction Function(EditiqueCatalogEntry entry)
  actionResolver;

  const DocumentsCatalogGroupCard({
    super.key,
    required this.group,
    required this.intent,
    required this.actionResolver,
  });

  @override
  Widget build(BuildContext context) {
    final entries = EditiqueCatalogEntry.ofGroup(group);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border.all(color: AppColors.border),
        borderRadius: AppRadius.brCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _GroupHead(group: group),
          const SizedBox(height: AppDimensions.spacingM),
          for (final entry in entries) ...[
            DocumentsCatalogRow(
              // Une instance de ligne par pièce, jamais recyclée entre deux
              // types : chaque ligne possède son BLoC d'émission.
              key: ValueKey('documents-row-${entry.code}'),
              entry: entry,
              action: actionResolver(entry),
              intent: intent,
            ),
            if (entry != entries.last)
              const SizedBox(height: AppDimensions.spacingS),
          ],
        ],
      ),
    );
  }
}

class _GroupHead extends StatelessWidget {
  static const double _medallionSize = 34;

  final EditiqueCatalogGroup group;

  const _GroupHead({required this.group});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _medallionSize,
          height: _medallionSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            DocumentsCatalogLabels.groupIconOf(group),
            size: 18,
            color: AppColors.bleuArdoise,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DocumentsCatalogLabels.groupTitleOf(l10n, group),
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DocumentsCatalogLabels.groupSubtitleOf(l10n, group),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
