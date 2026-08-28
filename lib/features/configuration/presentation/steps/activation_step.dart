import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_plan.dart';
import 'package:school_app_flutter/features/configuration/presentation/bloc/configuration_bloc.dart';
import 'package:school_app_flutter/features/configuration/presentation/cubit/school_identity_form_cubit.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/activation_checklist.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/summary_cards.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Étape 5 — récapitulatif et activation.
///
/// **Rien n'y est calculé.** Le récapitulatif EST la simulation, et l'activation
/// rejoue exactement le même calcul en écrivant. C'est ce qui garantit que ce
/// que l'écran promet est ce qui sera écrit.
class ActivationStep extends StatelessWidget {
  const ActivationStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ConfigurationBloc, ConfigurationState>(
      builder: (context, state) {
        final identity = context
            .watch<SchoolIdentityFormCubit>()
            .state
            .identity;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SummaryCards(state: state, identity: identity),
            const SizedBox(height: AppSpacing.lg),
            if (state.plan case final plan? when plan.warnings.isNotEmpty)
              _Warnings(warnings: plan.warnings),
            ActivationChecklist(state: state, identity: identity),
            if (state.failure != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.configurationActivateFailed,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Les avertissements du plan.
///
/// **Un avertissement n'empêche rien** : il dit ce que l'activation fera quand
/// même, et qui pourrait surprendre. Les messages sont servis rédigés en
/// français — les afficher tels quels, ne pas les traduire, et surtout ne pas
/// les tester : seul le code est stable.
class _Warnings extends StatelessWidget {
  final List<ProvisioningWarning> warnings;

  const _Warnings({required this.warnings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF4E4),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: const Color(0xFFEAD7A8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.configurationWarningsTitle,
                style: AppTypography.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final warning in warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(warning.message, style: AppTypography.bodySmall),
            ),
        ],
      ),
    );
  }
}

/// Écran de succès : l'école est en service.
class ActivationSuccessView extends StatelessWidget {
  final String schoolName;
  final ProvisioningPlan plan;
  final VoidCallback onGoHome;
  final VoidCallback onReview;

  const ActivationSuccessView({
    super.key,
    required this.schoolName,
    required this.plan,
    required this.onGoHome,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Color(0xFFEDF5EF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 44,
                color: AppColors.vertSavane,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.configurationActivatedTitle(schoolName),
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.configurationActivatedMessage(
                plan.academicYearName ?? '',
                plan.counts.classrooms,
                plan.counts.fees,
              ),
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(
                  onPressed: onGoHome,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, AppDimensions.minTouchTarget),
                  ),
                  child: Text(l10n.configurationGoHome),
                ),
                OutlinedButton(
                  onPressed: onReview,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppDimensions.minTouchTarget),
                  ),
                  child: Text(l10n.configurationReviewSetup),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
