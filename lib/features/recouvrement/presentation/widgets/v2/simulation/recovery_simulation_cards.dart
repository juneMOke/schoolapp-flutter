import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_overflow_text.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_parts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_table.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_verdict.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La simulation sous 600 reçus : une carte par classe, les
/// [visibleCount] plus touchées, puis « Voir les {n} autres classes » (I17,
/// A12) — avec 40 classes, la liste entière ferait plus de 4 000 dp.
class RecoverySimulationCards extends StatefulWidget {
  final List<RecoverySimulationRow> rows;
  final int unmanageableBelow;
  final ValueChanged<RecoverySimulationRow> onClassTapped;

  const RecoverySimulationCards({
    super.key,
    required this.rows,
    required this.unmanageableBelow,
    required this.onClassTapped,
  });

  static const visibleCount = 6;

  @override
  State<RecoverySimulationCards> createState() =>
      _RecoverySimulationCardsState();
}

class _RecoverySimulationCardsState extends State<RecoverySimulationCards> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const visible = RecoverySimulationCards.visibleCount;
    final rows = widget.rows;
    final hidden = rows.length - visible;
    final shown = _expanded || hidden <= 0 ? rows : rows.take(visible);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in shown) ...[
          _ClassCard(
            row: row,
            unmanageableBelow: widget.unmanageableBelow,
            onTap: row.targetedStudents > 0
                ? () => widget.onClassTapped(row)
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (hidden > 0)
          OutlinedButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, AppDimensions.minTouchTarget),
              foregroundColor: AppColors.bleuArdoise,
              side: const BorderSide(color: AppColors.border),
              textStyle: AppTypography.labelLarge,
            ),
            icon: Icon(
              _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            ),
            label: Text(
              _expanded
                  ? l10n.recoverySimulationShowLess(visible)
                  : l10n.recoverySimulationShowMore(hidden),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  final RecoverySimulationRow row;
  final int unmanageableBelow;
  final VoidCallback? onTap;

  const _ClassCard({
    required this.row,
    required this.unmanageableBelow,
    required this.onTap,
  });

  static const _radius = BorderRadius.all(
    Radius.circular(AppDimensions.recoverySimCardRadius),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final verdict = RecoveryVerdict.of(row, unmanageableBelow);
    final percent = recoveryKeptPercent(row.remainingHeadcount, row.headcount);
    final small = AppTypography.labelSmall.copyWith(
      color: AppColors.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    TextSpan figure(String label, String value, Color color) => TextSpan(
      children: [
        TextSpan(text: '$label '),
        TextSpan(
          text: value,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
    final opens = row.targetedStudents > 0;
    return EteeloActivatable(
      onActivate: onTap,
      semanticLabel: recoverySimulationRowA11y(row, unmanageableBelow, l10n),
      builder: (context, highlight) => Container(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md + AppDimensions.recoverySimCardStripe,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        // Deux couches : un rayon sous une bordure de deux couleurs lève au
        // `paint()`. Le tour gris dessous, le liseré du verdict par-dessus.
        decoration: BoxDecoration(
          color: highlight.hovered || highlight.focused
              ? AppColors.surfaceAlt
              : AppColors.surfaceRaised,
          borderRadius: _radius,
          border: Border.all(
            color: highlight.focused ? AppColors.bleuArdoise : AppColors.border,
          ),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: _radius,
          border: Border(
            left: BorderSide(
              color: verdict?.color ?? AppColors.textMuted,
              width: AppDimensions.recoverySimCardStripe,
            ),
          ),
        ),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: EteeloOverflowText(
                      row.classroomName,
                      // Le nom passe sur deux lignes plutôt que de céder
                      // devant la pastille (texte ×1,3 au téléphone).
                      maxLines: 2,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (verdict != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    RecoveryVerdictPill(verdict: verdict),
                  ],
                  if (opens) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const RecoverySimulationEye(),
                  ],
                ],
              ),
              if (row.cycleName case final cycle?)
                EteeloOverflowText(
                  cycle,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              RecoveryKeptBar(
                percent: percent,
                verdict: verdict,
                height: AppDimensions.recoverySimKeptBarCompactHeight,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  Text.rich(
                    figure(
                      l10n.recoverySimulationCardHeadcount,
                      '${row.headcount}',
                      AppColors.textPrimary,
                    ),
                    style: small,
                  ),
                  Text.rich(
                    figure(
                      l10n.recoverySimulationCardLeaving,
                      opens
                          ? l10n.recoverySimulationLeaving(row.targetedStudents)
                          : '0',
                      opens ? AppColors.error : AppColors.textMuted,
                    ),
                    style: small,
                  ),
                  Text.rich(
                    figure(
                      l10n.recoverySimulationCardRemaining,
                      '${row.remainingHeadcount}',
                      verdict?.ink ?? AppColors.textPrimary,
                    ),
                    style: small,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
