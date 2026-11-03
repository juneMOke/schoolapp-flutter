import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/layout/leading_trailing_row.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_input.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le pied du bulletin : la règle de calcul, ce qu'il reste à corriger, et
/// l'élève suivant. Une cote refusée s'y abandonne : sur une colonne clôturée,
/// c'est le seul geste qui lui reste.
class CoteBulletinFooter extends StatelessWidget {
  final VoidCallback? onStepped;

  const CoteBulletinFooter({super.key, this.onStepped});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<CoteSaisieBloc, CoteSaisieState>(
      buildWhen: (previous, current) => current is CoteSaisieReady,
      builder: (context, state) {
        if (state is! CoteSaisieReady) return const SizedBox.shrink();
        final calc = state.current;
        final group = CoteLabels.firstGroupShort(
          l10n,
          state.classe,
          state.columns,
        );
        final rejected = _rejected(state);
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final cell in rejected)
                _RejectedLine(cell: cell, state: state),
              LeadingTrailingRow(
                leading: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.coteFooterRule(group),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (calc.provisoire)
                      Text(
                        l10n.coteFooterProvisional(calc.filled, calc.cells),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (calc.invalid > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: AppDimensions.coteInlineIconSize,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                l10n.coteFooterInvalid(calc.invalid),
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                trailing: EteeloButton.primary(
                  label: l10n.coteStudentNext,
                  icon: Icons.chevron_right_rounded,
                  fullWidth: false,
                  onPressed: state.hasNext
                      ? () {
                          context.read<CoteSaisieBloc>().add(
                            const CoteStudentStepped(1),
                          );
                          onStepped?.call();
                        }
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Les refus de l'élève courant, portée ou non : le serveur n'en garde rien,
  /// ils ne doivent pas se perdre hors de la vue.
  List<CoteCell> _rejected(CoteSaisieReady state) => [
    for (final cours in state.cours)
      for (final column in state.year)
        if (column.isInput) ...[
          ?state.cells
              .cell(state.currentId, cours.coursId, column.id)
              ?.rejectedOrNull,
        ],
  ];
}

class _RejectedLine extends StatelessWidget {
  final CoteCell cell;
  final CoteSaisieReady state;

  const _RejectedLine({required this.cell, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final key = cell.key;
    final CoteCours cours = state.cours.firstWhere(
      (c) => c.coursId == key.coursId,
    );
    final CoteColumn column = state.year.firstWhere(
      (c) => c.isInput && c.id == key.colonneId,
    );
    final value = cell.draftValue;
    final official = cell.serverCote ?? cell.calculee;
    final title =
        '${cours.branche} · ${CoteLabels.columnLong(l10n, state.classe, column)}'
        '${value == null ? '' : ' : ${formatCote(value)}'}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        color: AppColors.coteInvalidSurface,
        child: LeadingTrailingRow(
          leading: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                CoteLabels.rejection(l10n, cell.rejectionReason),
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
              if (official != null)
                Text(
                  l10n.coteRejectedOfficial(formatCote(official)),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          trailing: EteeloButton.ghost(
            label: l10n.coteRejectedDiscard,
            fullWidth: false,
            onPressed: () =>
                context.read<CoteSaisieBloc>().add(CoteRejectedDiscarded(key)),
          ),
        ),
      ),
    );
  }
}
