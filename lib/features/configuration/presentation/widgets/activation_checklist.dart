import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/school_identity.dart';
import 'package:school_app_flutter/features/configuration/presentation/bloc/configuration_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre contrôles qui gardent l'activation.
///
/// Un contrôle non satisfait est **ambre et cliquable** : il renvoie à l'étape
/// qui le débloque. Satisfait, il est vert et inerte — il n'y a plus rien à y
/// faire.
class ActivationChecklist extends StatelessWidget {
  final ConfigurationState state;
  final SchoolIdentity? identity;

  const ActivationChecklist({super.key, required this.state, this.identity});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final schoolComplete = identity?.isComplete ?? false;
    final checks = <(bool, String, ConfigurationStep)>[
      (schoolComplete, l10n.configurationCheckSchool, ConfigurationStep.school),
      (
        state.hasDatedYear,
        l10n.configurationCheckYear,
        ConfigurationStep.academicYear,
      ),
      (
        state.hasClassrooms,
        l10n.configurationCheckClassrooms(state.counts.classrooms),
        ConfigurationStep.structure,
      ),
      (
        state.hasFees,
        l10n.configurationCheckFees(state.draft.fees.length),
        ConfigurationStep.fees,
      ),
    ];

    final allPassed = checks.every((check) => check.$1);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: allPassed ? const Color(0xFFEDF5EF) : AppColors.surfaceAlt,
        borderRadius: AppRadius.brCard,
        border: Border.all(
          color: allPassed ? const Color(0xFFBFD8C6) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (passed, label, step) in checks)
                _Check(passed: passed, label: label, step: step),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!allPassed)
            Text(
              l10n.configurationActivateBlocked,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  final bool passed;
  final String label;
  final ConfigurationStep step;

  const _Check({required this.passed, required this.label, required this.step});

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          passed ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          size: 17,
          color: passed ? AppColors.vertSavane : AppColors.warning,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: passed ? AppColors.vertSavane : AppColors.warning,
            ),
          ),
        ),
      ],
    );

    // Satisfait : inerte. Il n'y a plus rien à faire sur cette étape, et un
    // lien y inviterait pour rien.
    if (passed) return content;

    return InkWell(
      onTap: () => context.read<ConfigurationBloc>().add(
        ConfigurationStepSelected(step),
      ),
      borderRadius: AppRadius.brSm,
      child: content,
    );
  }
}
