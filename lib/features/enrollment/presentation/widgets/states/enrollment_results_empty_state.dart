import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentResultsEmptyState extends StatelessWidget {
  final List<String> criteria;
  final VoidCallback? onReset;
  final VoidCallback? onCreateEnrollment;

  const EnrollmentResultsEmptyState({
    super.key,
    this.criteria = const <String>[],
    this.onReset,
    this.onCreateEnrollment,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasCriteria = criteria.isNotEmpty;

    final criteriaChips = criteria
        .map(
          (item) => Chip(
            label: Text(item),
            backgroundColor: AppColors.surfaceAlt,
            labelStyle: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            side: const BorderSide(color: AppColors.border),
            visualDensity: VisualDensity.compact,
          ),
        )
        .toList(growable: false);

    return EteeloEmptyResult(
      label: l10n.enrollmentEmptyTitle,
      description: hasCriteria
          ? l10n.enrollmentEmptyDescription
          : l10n.enrollmentEmptyWithoutFilterDescription,
      criteriaChips: criteriaChips,
      cornerBadgeIcon: hasCriteria ? Icons.filter_list_rounded : null,
      secondaryAction: onReset == null
          ? null
          : OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.clear),
            ),
      primaryAction: onCreateEnrollment == null
          ? null
          : FilledButton.icon(
              onPressed: onCreateEnrollment,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
              label: Text(l10n.enrollmentEmptyCreateAction),
            ),
      autofocusPrimaryAction: onCreateEnrollment != null,
      fullWidthCard: true,
    );
  }
}
