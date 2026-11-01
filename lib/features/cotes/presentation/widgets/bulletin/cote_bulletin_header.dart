import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_overflow_text.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau de l'élève courant : identité, chiffres et passage à l'élève
/// voisin. Sur téléphone, les chiffres passent sous l'identité.
class CoteBulletinHeader extends StatelessWidget {
  final String classroomName;

  /// L'élève change au clavier ou au bouton : la grille reprend le focus.
  final VoidCallback? onStepped;

  const CoteBulletinHeader({
    super.key,
    required this.classroomName,
    this.onStepped,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<CoteSaisieBloc, CoteSaisieState>(
      buildWhen: (previous, current) => current is CoteSaisieReady,
      builder: (context, state) {
        if (state is! CoteSaisieReady) return const SizedBox.shrink();
        final eleve = state.currentEleve;
        final calc = state.current;
        final rank = state.ranking.rangs[state.currentId];
        final percent = calc.pct;
        final subtitle = l10n.coteHeaderSubtitle(
          classroomName,
          CoteLabels.scope(l10n, state.classe, state.scope, state.columns),
          state.currentIndex + 1,
          state.eleves.length,
        );
        final identity = Row(
          children: [
            PersonAvatar(
              firstName: eleve.firstName,
              lastName: eleve.lastName,
              personId: eleve.studentId,
              size: AppDimensions.coteHeaderAvatar,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  EteeloOverflowText(
                    eleve.fullName,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textOnDark,
                    ),
                  ),
                  EteeloOverflowText(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textOnDark.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        final kpis = Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Kpi(
              value: percent == null ? '—' : l10n.cotePercent(percent),
              label: calc.provisoire && percent != null
                  ? l10n.coteKpiProvisional
                  : l10n.coteKpiPercent,
              valueColor: AppColors.orDoux,
            ),
            _Kpi(
              value: rank == null ? l10n.coteRankNone : l10n.coteRank(rank),
              label: rank == null
                  ? l10n.coteRankNoneLong
                  : l10n.coteKpiRankOf(state.ranking.classes),
            ),
            _Kpi(
              value: '${calc.filled}/${calc.cells}',
              label: l10n.coteKpiFilled,
            ),
            _StepButton(
              icon: Icons.chevron_left_rounded,
              tooltip: l10n.coteStudentPrevious,
              onPressed: state.hasPrevious ? () => _step(context, -1) : null,
            ),
            _StepButton(
              icon: Icons.chevron_right_rounded,
              tooltip: l10n.coteStudentNext,
              onPressed: state.hasNext ? () => _step(context, 1) : null,
            ),
          ],
        );
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Les chiffres et les flèches prennent environ 440 dp : en deçà
              // d'une colonne d'identité lisible, ils passent dessous.
              final stacked =
                  constraints.maxWidth <
                  AppDimensions.coteHeaderKpiMinWidth * 8;
              return stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        identity,
                        const SizedBox(height: AppSpacing.md),
                        kpis,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: identity),
                        const SizedBox(width: AppSpacing.md),
                        kpis,
                      ],
                    );
            },
          ),
        );
      },
    );
  }

  void _step(BuildContext context, int delta) {
    context.read<CoteSaisieBloc>().add(CoteStudentStepped(delta));
    onStepped?.call();
  }
}

class _Kpi extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _Kpi({
    required this.value,
    required this.label,
    this.valueColor = AppColors.textOnDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: AppDimensions.coteHeaderKpiMinWidth,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.textOnDark.withValues(alpha: 0.09),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.textOnDark.withValues(alpha: 0.14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            style: AppTypography.titleMedium.copyWith(
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            maxLines: 1,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textOnDark.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      constraints: const BoxConstraints(
        minWidth: AppDimensions.minTouchTarget,
        minHeight: AppDimensions.minTouchTarget,
      ),
      tooltip: tooltip,
      onPressed: onPressed,
      color: AppColors.textOnDark,
      disabledColor: AppColors.textOnDark.withValues(alpha: 0.35),
      icon: Icon(icon),
    );
  }
}
