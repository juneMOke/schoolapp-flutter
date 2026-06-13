import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_summary.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_card.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

enum DisciplinaryCasesBodyStatus { loading, empty, error, success }

/// Zone d'état de la liste des cas : squelette / vide / erreur (widgets
/// partagés) ou liste de [DisciplinaryCaseCard].
class DisciplinaryCasesStateBody extends StatelessWidget {
  final DisciplinaryCasesBodyStatus status;
  final List<DisciplinaryCaseSummary> cases;
  final DisciplinaryCaseErrorType errorType;
  final VoidCallback? onRetry;
  final VoidCallback? onReconnect;
  final VoidCallback? onContactAdmin;
  final VoidCallback? onCreateCase;

  /// Avancement de statut (dormant pour l'instant).
  final void Function(DisciplinaryCaseSummary caseData)? onAdvance;

  const DisciplinaryCasesStateBody({
    super.key,
    required this.status,
    required this.cases,
    required this.errorType,
    this.onRetry,
    this.onReconnect,
    this.onContactAdmin,
    this.onCreateCase,
    this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final child = switch (status) {
      DisciplinaryCasesBodyStatus.loading => const _Skeleton(),
      DisciplinaryCasesBodyStatus.empty => _empty(context),
      DisciplinaryCasesBodyStatus.error => DisciplinaryCaseResultsErrorState(
        type: errorType,
        onRetry: onRetry,
        onReconnect: onReconnect,
        onContactAdmin: onContactAdmin,
      ),
      DisciplinaryCasesBodyStatus.success => _list(),
    };

    // reduced-motion : bascule instantanée entre états (pas de fondu enchaîné).
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : AppMotion.standard,
      switchInCurve: AppMotion.outCurve,
      switchOutCurve: AppMotion.inCurve,
      child: KeyedSubtree(
        key: ValueKey('${status.name}-${cases.length}-${errorType.name}'),
        child: child,
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloEmptyResult(
      medallionIcon: Icons.check_circle_outline_rounded,
      label: l10n.disciplinaryCasesEmptyTitle,
      description: l10n.disciplinaryCasesEmptyDescription,
      secondaryAction: onCreateCase == null
          ? null
          : OutlinedButton.icon(
              onPressed: onCreateCase,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(l10n.disciplinaryCaseCreateAction),
            ),
      fullWidthCard: true,
      minHeight: 280,
    );
  }

  Widget _list() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < cases.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == cases.length - 1 ? 0 : AppDimensions.spacingM,
            ),
            child: DisciplinaryCaseCard(
              caseData: cases[i],
              onAdvance: onAdvance == null ? null : () => onAdvance!(cases[i]),
            ),
          ),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.disciplinaryCasesLoadingMessage,
      child: const ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppDimensions.spacingM,
              runSpacing: AppDimensions.spacingM,
              children: [_GhostSummary(), _GhostSummary(), _GhostSummary()],
            ),
            SizedBox(height: AppDimensions.spacingM),
            _GhostCaseCard(),
            SizedBox(height: AppDimensions.spacingM),
            _GhostCaseCard(),
          ],
        ),
      ),
    );
  }
}

class _GhostSummary extends StatelessWidget {
  const _GhostSummary();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.enrollmentStatsKpiCardMinWidth,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(
            AppDimensions.enrollmentStatsChartRadius,
          ),
          border: const Border(
            left: BorderSide(color: AppColors.border, width: 3),
          ),
        ),
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            EteeloSkeletonBox(
              width: 26,
              height: 26,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            SizedBox(height: AppDimensions.spacingS),
            EteeloSkeletonBox(width: 50, height: 18),
            SizedBox(height: AppDimensions.spacingXS),
            EteeloSkeletonBox(width: 78, height: 9),
          ],
        ),
      ),
    );
  }
}

class _GhostCaseCard extends StatelessWidget {
  const _GhostCaseCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingL,
        vertical: AppDimensions.spacingM,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: EteeloSkeletonBox(width: 140, height: 14)),
              SizedBox(width: AppDimensions.spacingS),
              EteeloSkeletonBox(
                width: 88,
                height: 26,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.spacingS),
          EteeloSkeletonBox(width: double.infinity, height: 10),
          SizedBox(height: AppDimensions.spacingXS),
          EteeloSkeletonBox(width: 200, height: 10),
        ],
      ),
    );
  }
}
