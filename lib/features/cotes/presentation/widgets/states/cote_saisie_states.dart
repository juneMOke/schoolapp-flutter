import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'invite : le bouton d'ouverture est dans la carte de sélection.
class CoteSaisieIdleState extends StatelessWidget {
  const CoteSaisieIdleState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloEmptyResult(
      medallionIcon: Icons.edit_outlined,
      label: l10n.coteIdleTitle,
      description: l10n.coteIdleDescription,
      fullWidthCard: true,
    );
  }
}

class CoteSaisieEmptyState extends StatelessWidget {
  final CoteEmptyReason reason;
  final VoidCallback onChangeClass;

  const CoteSaisieEmptyState({
    super.key,
    required this.reason,
    required this.onChangeClass,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final noStudents = reason == CoteEmptyReason.noStudents;
    return EteeloEmptyResult(
      medallionIcon: noStudents
          ? Icons.groups_outlined
          : Icons.menu_book_outlined,
      label: noStudents
          ? l10n.coteEmptyStudentsTitle
          : l10n.coteEmptyCoursesTitle,
      description: noStudents
          ? l10n.coteEmptyStudentsDescription
          : l10n.coteEmptyCoursesDescription,
      primaryAction: EteeloButton.secondary(
        label: l10n.coteEmptyChangeClass,
        fullWidth: false,
        onPressed: onChangeClass,
      ),
      fullWidthCard: true,
    );
  }
}

/// Le squelette garde la mise en page : la liste si elle tient, le bandeau de
/// l'élève, puis les lignes de la grille. Jamais de spinner centré.
class CoteSaisieSkeleton extends StatelessWidget {
  const CoteSaisieSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final grid = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EteeloSkeletonBox(height: AppDimensions.coteSkeletonHeader),
        for (var i = 0; i < AppDimensions.coteSkeletonGridRows; i++) ...[
          const SizedBox(height: AppSpacing.sm),
          const EteeloSkeletonBox(height: AppDimensions.minTouchTarget),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppBreakpoints.coteGridCompactMax) {
          return grid;
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: AppDimensions.coteListPanelWidth,
              child: Column(
                children: [
                  for (var i = 0; i < AppDimensions.coteSkeletonListRows; i++)
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: EteeloSkeletonBox(
                        height: AppDimensions.coteListRowHeight,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.coteListGap),
            Expanded(child: grid),
          ],
        );
      },
    );
  }
}
