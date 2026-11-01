import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_overflow_text.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_calculator.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_layout.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne de la liste. Son calcul, son rang et la sélection se lisent à part :
/// le rang peut bouger sur une frappe faite chez un autre élève.
class CoteStudentTile extends StatelessWidget {
  final CoteEleve eleve;
  final VoidCallback? onSelected;

  const CoteStudentTile({super.key, required this.eleve, this.onSelected});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      CoteSaisieBloc,
      CoteSaisieState,
      (CoteEleveCalc?, int?, bool)
    >(
      selector: (state) => state is CoteSaisieReady
          ? (
              state.calcs[eleve.studentId],
              state.ranking.rangs[eleve.studentId],
              state.currentId == eleve.studentId,
            )
          : (null, null, false),
      builder: (context, data) {
        final (calc, rank, current) = data;
        return _tile(context, calc, rank, current);
      },
    );
  }

  Widget _tile(
    BuildContext context,
    CoteEleveCalc? calc,
    int? rank,
    bool current,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final percent = calc?.pct;
    final missing = calc == null ? 0 : calc.cells - calc.filled - calc.invalid;
    final subtitle = calc == null
        ? ''
        : calc.invalid > 0
        ? l10n.coteListToFix(calc.invalid)
        : missing > 0
        ? l10n.coteListMissing(missing)
        : l10n.coteListComplete;
    return Semantics(
      selected: current,
      button: true,
      child: InkWell(
        onTap: () {
          if (current) return;
          context.read<CoteSaisieBloc>().add(
            CoteStudentSelected(eleve.studentId),
          );
          onSelected?.call();
        },
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppDimensions.coteListRowHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: current ? AppColors.bleuArdoiseSoft : null,
            border: Border(
              left: BorderSide(
                color: current ? AppColors.bleuArdoise : Colors.transparent,
                width: 3,
              ),
              top: const BorderSide(color: AppColors.border),
            ),
          ),
          child: Row(
            children: [
              _avatar(calc),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EteeloOverflowText(
                      eleve.fullName,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.noirChaud,
                        fontWeight: current ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    EteeloOverflowText(
                      subtitle,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    percent == null ? '—' : l10n.cotePercent(percent),
                    style: AppTypography.bodySmall.copyWith(
                      color: cotePercentColor(percent),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    rank == null ? l10n.coteRankNone : l10n.coteRank(rank),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(CoteEleveCalc? calc) {
    final invalid = (calc?.invalid ?? 0) > 0;
    final complete = calc?.complete ?? false;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PersonAvatar(
          firstName: eleve.firstName,
          lastName: eleve.lastName,
          personId: eleve.studentId,
        ),
        if (invalid || complete)
          Positioned(
            right: -AppDimensions.coteStatusBadgeOffset,
            bottom: -AppDimensions.coteStatusBadgeOffset,
            child: Container(
              width: AppDimensions.coteStatusBadge,
              height: AppDimensions.coteStatusBadge,
              decoration: BoxDecoration(
                color: invalid ? AppColors.error : AppColors.vertSavane,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceRaised, width: 2),
              ),
              child: Icon(
                invalid ? Icons.priority_high_rounded : Icons.check_rounded,
                size: AppDimensions.coteStatusBadgeIcon,
                color: AppColors.textOnDark,
              ),
            ),
          ),
      ],
    );
  }
}
