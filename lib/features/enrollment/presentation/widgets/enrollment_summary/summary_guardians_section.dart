import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_guardian_compact_line.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_section_card.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_step_constants.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_utils.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SummaryGuardiansSection extends StatelessWidget {
  final List<ParentSummary> parents;
  final ValueChanged<int> onEditRequested;

  const SummaryGuardiansSection({
    super.key,
    required this.parents,
    required this.onEditRequested,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SummarySectionCard(
      title: l10n.guardianInformation,
      icon: Icons.groups_outlined,
      onEdit: () => onEditRequested(EnrollmentSummarySteps.guardians),
      child: parents.isEmpty
          ? Text(
              l10n.noGuardianInfo,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            )
          : Column(
              children: List<Widget>.generate(parents.length, (index) {
                final parent = parents[index];
                // Convention temporaire: le premier parent reçu est affiché principal.
                final isPrimary = index == 0;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == parents.length - 1
                        ? 0
                        : AppDimensions.spacingS,
                  ),
                  child: SummaryGuardianCompactLine(
                    parent: parent,
                    isPrimary: isPrimary,
                    relationshipLabel: EnrollmentSummaryUtils.relationshipLabel(
                      parent.relationshipType,
                      l10n,
                    ),
                  ),
                );
              }),
            ),
    );
  }
}
