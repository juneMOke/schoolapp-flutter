import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_catalog_entry.dart';
import 'package:school_app_flutter/features/documents/presentation/models/documents_catalog_action.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/catalog/documents_catalog_action_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le texte d'une ligne : titre et nature, sous-titre, message, puis le
/// [footer] (les gestes, quand la ligne est empilée).
class DocumentsCatalogRowDetails extends StatelessWidget {
  final String title;
  final EditiqueCatalogNature nature;
  final String subtitle;
  final DocumentsCatalogAction action;
  final Widget? footer;

  const DocumentsCatalogRowDetails({
    super.key,
    required this.title,
    required this.nature,
    required this.subtitle,
    required this.action,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingXS,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            DocumentsCatalogNatureBadge(nature: nature),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        DocumentsCatalogRowNotice(action: action),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.spacingS),
            child: footer,
          ),
      ],
    );
  }
}

/// Médaillon 44 dp à l'accent de la pièce, avec sa pastille de code.
///
/// La pastille est **décorative** : le titre complet est toujours lu à côté,
/// donc elle est masquée aux lecteurs d'écran plutôt que de leur faire épeler
/// deux lettres sans contexte.
class DocumentsCatalogCodeMedallion extends StatelessWidget {
  static const double _size = 44;

  final String code;
  final Color accent;

  const DocumentsCatalogCodeMedallion({
    super.key,
    required this.code,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.14),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          code,
          style: AppTypography.labelSmall.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Badge de nature (§08).
///
/// Jamais porté par la seule couleur : une icône explicite (cadenas / horloge)
/// double le libellé, conformément au contrat d'accessibilité du module.
class DocumentsCatalogNatureBadge extends StatelessWidget {
  final EditiqueCatalogNature nature;

  const DocumentsCatalogNatureBadge({super.key, required this.nature});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFige = nature == EditiqueCatalogNature.fige;

    final Color foreground = isFige
        ? AppColors.bleuArdoise
        : AppColors.documentsHorodateText;
    final Color background = isFige
        ? AppColors.bleuArdoiseSoft
        : AppColors.documentsHorodateSoft;
    final Color borderColor = isFige
        ? AppColors.documentsFigeBorder
        : AppColors.documentsHorodateBorder;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFige ? Icons.lock_outline_rounded : Icons.schedule_rounded,
            size: 12,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            isFige
                ? l10n.documentsNatureArchivedLabel
                : l10n.documentsNatureTimestampedLabel,
            style: AppTypography.labelSmall.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
