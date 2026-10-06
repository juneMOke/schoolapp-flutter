import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_objectif.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/detail/chapitre_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les objectifs, à cocher une fois atteints — enregistré aussitôt. Cocher
/// ne change jamais le statut du chapitre : le professeur le change lui-même.
/// Sans droit d'écriture ([onToggle] `null`), les cases se lisent seulement.
class ChapitreObjectifsSection extends StatelessWidget {
  final List<ChapitreObjectif> objectifs;
  final ValueChanged<String>? onToggle;

  const ChapitreObjectifsSection({
    super.key,
    required this.objectifs,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final toggle = onToggle;
    return ChapitreSection(
      icon: Icons.flag_outlined,
      title: l10n.chapitreSectionObjectifs,
      count: objectifs.length,
      child: objectifs.isEmpty
          ? ChapitreSectionEmpty(l10n.chapitreObjectifsEmpty)
          : Column(
              children: [
                for (final objectif in objectifs)
                  CheckboxListTile(
                    key: ValueKey<String>(objectif.id),
                    value: objectif.atteint,
                    onChanged: toggle == null
                        ? null
                        : (_) => toggle(objectif.id),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.programmeTermine,
                    title: Text(
                      objectif.texte,
                      style: AppTypography.bodyMedium.copyWith(
                        color: objectif.atteint
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        decoration: objectif.atteint
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
