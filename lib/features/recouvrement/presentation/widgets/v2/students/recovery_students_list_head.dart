import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_student_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau d'en-tête de la liste (terre cuite assombrie, encre crème) —
/// mêmes parts de colonnes que les lignes ; aucun en-tête en cartes.
class RecoveryStudentsListHead extends StatelessWidget {
  final RecoveryStudentRowLayout layout;

  const RecoveryStudentsListHead({super.key, required this.layout});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = AppTypography.labelSmall.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.blancCasse,
    );
    Widget cell(String text, int flex, {bool end = false}) => Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: end ? TextAlign.end : TextAlign.start,
        style: style,
      ),
    );
    final cells = layout == RecoveryStudentRowLayout.compact
        ? [
            cell(l10n.recoveryStudentsColStudentClass, recoveryCompactFlex[0]),
            cell(
              l10n.recoveryStudentsColOutstandingPaid,
              recoveryCompactFlex[1],
              end: true,
            ),
            cell(l10n.recoveryStudentsColSituation, recoveryCompactFlex[2]),
          ]
        : [
            cell(l10n.recoveryStudentsColStudent, recoveryWideFlex[0]),
            cell(l10n.recoveryStudentsColClass, recoveryWideFlex[1]),
            cell(l10n.recoveryStudentsColPaid, recoveryWideFlex[2], end: true),
            cell(
              l10n.recoveryStudentsColOutstanding,
              recoveryWideFlex[3],
              end: true,
            ),
            cell(l10n.recoveryStudentsColSituation, recoveryWideFlex[4]),
          ];
    return Container(
      color: DashboardTones.entete(AppColors.terreCuite),
      // Le liseré des lignes décale leur contenu : l'en-tête le reprend.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md + 2 + AppDimensions.recoveryStudentsRowStripe,
        AppSpacing.sm + 1,
        AppSpacing.md + 2,
        AppSpacing.sm + 1,
      ),
      child: Row(
        spacing: AppSpacing.sm + 2,
        children: [
          ...cells,
          const SizedBox(width: AppDimensions.recoveryStudentsEyeSize),
        ],
      ),
    );
  }
}
