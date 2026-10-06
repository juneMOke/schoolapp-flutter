import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/programme_layout.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Chargement d'un programme ou d'un chapitre : l'en-tête (médaillon + deux
/// lignes) puis quatre rangées fantômes. Le scintillement s'arrête en
/// mouvement réduit ([EteeloSkeletonBox]).
class ProgrammeSkeleton extends StatelessWidget {
  /// Ce que le chargement annonce ; celui du programme par défaut.
  final String? semanticsLabel;

  const ProgrammeSkeleton({super.key, this.semanticsLabel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            EteeloSkeletonBox(
              width: ProgrammeLayout.headerMedallion,
              height: ProgrammeLayout.headerMedallion,
              borderRadius: AppRadius.brLg,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.4,
                    child: EteeloSkeletonBox(height: 20),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  FractionallySizedBox(
                    widthFactor: 0.25,
                    child: EteeloSkeletonBox(height: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        EteeloListSkeleton(
          rowCount: 4,
          pillCount: 1,
          semanticsLabel: semanticsLabel ?? l10n.programmeLoadingA11yLabel,
        ),
      ],
    );
  }
}
