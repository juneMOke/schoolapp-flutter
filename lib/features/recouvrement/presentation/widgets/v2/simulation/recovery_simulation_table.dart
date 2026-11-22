import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_overflow_text.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_parts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_verdict.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le tableau de la simulation, dès 600 reçus : 680 dp au moins
/// (`recouvrementSimTableMinWidth`), et en deçà il défile de côté sous un
/// ascenseur visible (A13). L'ordre est celui du serveur.
class RecoverySimulationTable extends StatelessWidget {
  final List<RecoverySimulationRow> rows;
  final int unmanageableBelow;
  final ValueChanged<RecoverySimulationRow> onClassTapped;

  const RecoverySimulationTable({
    super.key,
    required this.rows,
    required this.unmanageableBelow,
    required this.onClassTapped,
  });

  static const _widths = <double?>[
    null,
    AppDimensions.recoverySimColHeadcount,
    AppDimensions.recoverySimColLeaving,
    AppDimensions.recoverySimColRemaining,
    null,
    AppDimensions.recoverySimColVerdict,
    AppDimensions.recoverySimColEye,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloColumnTable(
      minWidth: AppDimensions.recouvrementSimTableMinWidth,
      widths: _widths,
      tone: ListingTones.tableTone(AppColors.terreCuite),
      endAligned: const {1, 2, 3},
      headers: [
        l10n.recoverySimulationColClass,
        l10n.recoverySimulationColHeadcount,
        l10n.recoverySimulationColLeaving,
        l10n.recoverySimulationColRemaining,
        l10n.recoverySimulationColKept,
        l10n.recoverySimulationColVerdict,
        '',
      ],
      rowCount: rows.length,
      row: (context, index) => _row(context, rows[index], l10n),
    );
  }

  Widget _row(
    BuildContext context,
    RecoverySimulationRow row,
    AppLocalizations l10n,
  ) {
    final verdict = RecoveryVerdict.of(row, unmanageableBelow);
    final percent = recoveryKeptPercent(row.remainingHeadcount, row.headcount);
    final opens = row.targetedStudents > 0;
    return Semantics(
      button: opens,
      label: _a11y(row, percent, verdict, l10n),
      excludeSemantics: true,
      child: EteeloColumnTableRow(
        widths: _widths,
        onTap: opens ? () => onClassTapped(row) : null,
        cells: [
          _ClassCell(row: row),
          _figure(
            '${row.headcount}',
            AppTypography.bodyMedium,
            AppColors.textSecondary,
          ),
          _figure(
            opens ? l10n.recoverySimulationLeaving(row.targetedStudents) : '0',
            AppTypography.labelLarge,
            opens ? AppColors.error : AppColors.textMuted,
          ),
          _figure(
            '${row.remainingHeadcount}',
            AppTypography.labelLarge,
            verdict?.ink ?? AppColors.textPrimary,
          ),
          RecoveryKeptBar(percent: percent, verdict: verdict),
          Container(
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
            child: verdict == null
                ? const SizedBox.shrink()
                : RecoveryVerdictPill(verdict: verdict),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: opens
                ? const RecoverySimulationEye()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  static Widget _figure(String text, TextStyle style, Color color) =>
      EteeloOverflowText(
        text,
        textAlign: TextAlign.end,
        style: style.copyWith(
          color: color,
          fontWeight: style == AppTypography.labelLarge
              ? FontWeight.w700
              : null,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
}

/// D10 parlé : « 3ème primaire : 36 → 4 élèves, 11 % conservés, Ingérable ».
String recoverySimulationRowA11y(
  RecoverySimulationRow row,
  int unmanageableBelow,
  AppLocalizations l10n,
) => _a11y(
  row,
  recoveryKeptPercent(row.remainingHeadcount, row.headcount),
  RecoveryVerdict.of(row, unmanageableBelow),
  l10n,
);

String _a11y(
  RecoverySimulationRow row,
  int percent,
  RecoveryVerdict? verdict,
  AppLocalizations l10n,
) {
  final base = l10n.recoverySimulationRowA11y(
    row.classroomName,
    row.headcount,
    row.remainingHeadcount,
    percent,
  );
  final withVerdict = verdict == null ? base : '$base, ${verdict.label(l10n)}';
  return row.targetedStudents > 0
      ? '$withVerdict. ${l10n.recoverySimulationOpenList(row.classroomName)}'
      : withVerdict;
}

class _ClassCell extends StatelessWidget {
  final RecoverySimulationRow row;

  const _ClassCell({required this.row});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      EteeloOverflowText(
        row.classroomName,
        maxLines: 2,
        style: AppTypography.titleSmall.copyWith(color: AppColors.textPrimary),
      ),
      if (row.cycleName case final cycle?)
        EteeloOverflowText(
          cycle,
          style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
        ),
    ],
  );
}
