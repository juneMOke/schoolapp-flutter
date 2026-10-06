import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_labels.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_detail.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/detail/chapitre_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les évaluations qui portent sur le chapitre ; un tap ouvre le cours dans
/// « Mes évaluations ».
class ChapitreEvaluationsSection extends StatelessWidget {
  final List<ChapitreEvaluationLink> evaluations;
  final VoidCallback onOpen;

  const ChapitreEvaluationsSection({
    super.key,
    required this.evaluations,
    required this.onOpen,
  });

  static String _points(double max) =>
      max == max.roundToDouble() ? max.toInt().toString() : '$max';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ChapitreSection(
      icon: Icons.assignment_outlined,
      title: l10n.chapitreSectionEvaluations,
      count: evaluations.length,
      child: evaluations.isEmpty
          ? ChapitreSectionEmpty(l10n.chapitreEvaluationsEmpty)
          : Column(
              children: [
                for (var i = 0; i < evaluations.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  ListTile(
                    key: ValueKey<String>(evaluations[i].id),
                    onTap: onOpen,
                    leading: const Icon(
                      Icons.assignment_turned_in_outlined,
                      color: AppColors.bleuArdoise,
                    ),
                    title: Text(
                      typeEvaluationLabel(l10n, evaluations[i].type),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      l10n.chapitreEvaluationLine(
                        evaluations[i].date,
                        _points(evaluations[i].maxPoints),
                      ),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
