import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/calendars_section.dart';

/// Le chargement de la liste (spec §5) : le bandeau, puis deux cartes, dans
/// l'anatomie de l'écran prêt (maquette `CalListSkeleton`).
class CalendarsListSkeleton extends StatelessWidget {
  final String semanticsLabel;

  const CalendarsListSkeleton({super.key, required this.semanticsLabel});

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    child: ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EteeloSkeletonBox(
            height: AppDimensions.calendarHeroSkeletonHeight,
            borderRadius: AppRadius.brCard,
          ),
          const SizedBox(height: AppSpacing.lg),
          CalendarsGrid(children: [for (var i = 0; i < 2; i++) _card()]),
        ],
      ),
    ),
  );

  Widget _card() => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadius.brLg,
      border: Border.all(color: AppColors.border),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            EteeloSkeletonBox(
              width: AppDimensions.calendarCardMedallion,
              height: AppDimensions.calendarCardMedallion,
              borderRadius: AppRadius.brMd,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.5,
                    child: EteeloSkeletonBox(height: AppSpacing.md),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  FractionallySizedBox(
                    widthFactor: 0.7,
                    child: EteeloSkeletonBox(height: AppSpacing.sm),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        FractionallySizedBox(
          widthFactor: 0.6,
          child: EteeloSkeletonBox(
            height: AppSpacing.lg,
            borderRadius: AppRadius.brPill,
          ),
        ),
      ],
    ),
  );
}
