import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/settings_tariffs_panel.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La structure, telle qu'elle existe une fois l'école en service.
///
/// **En lecture, et c'est une décision de sécurité, pas d'ergonomie.** Les
/// routes de suppression de niveau et de cycle existent côté serveur, mais elles
/// ne vérifient ni l'appartenance à l'école de l'appelant, ni que la cible est
/// vide : ces entités ne portent pas de colonne `school_id`, donc le filtre de
/// cloisonnement ne les couvre pas. Sur un niveau peuplé, la base rend une
/// violation de clé étrangère remontée en 500, pas le 409 que cet écran devrait
/// afficher. Câbler l'un ou l'autre ici risquerait de casser des inscriptions en
/// cours.
///
/// Elle sert aussi de colonne vertébrale à l'onglet Frais : les tarifs se
/// gèrent **par niveau**, puisque c'est ce qu'un tarif porte.
class SettingsStructureView extends StatelessWidget {
  final List<SchoolLevelGroupBundle> bundles;

  /// Onglet Frais : chaque niveau déplie ses tarifs.
  final bool showTariffs;

  final String? academicYearId;

  const SettingsStructureView({
    super.key,
    required this.bundles,
    this.showTariffs = false,
    this.academicYearId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 17,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  showTariffs
                      ? l10n.configurationSettingsTariffOne
                      : l10n.configurationSettingsStructureReadOnlyNote,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final bundle in bundles)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: AppRadius.brCard,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  bundle.group.name,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final level in bundle.levels)
                  if (showTariffs)
                    SettingsTariffsPanel(
                      key: ValueKey<String>(level.id),
                      levelId: level.id,
                      levelName: level.name,
                      schoolLevelGroupId: bundle.group.id,
                      academicYearId: academicYearId ?? '',
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          Expanded(
                            child: Text(
                              level.name,
                              style: AppTypography.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
      ],
    );
  }
}
