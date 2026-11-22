import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_class_visual.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/timetable_trace.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'identité d'une classe (EDT §4.6 B), à la place du titre de semaine : un
/// repère à la couleur de la classe, le nom, la salle, le statut, puis la
/// traçabilité (D3) et, sous 600 reçus, les comptes en texte (D7).
class ClassTimetableIdentity extends StatelessWidget {
  final ClassTimetableView view;

  /// Le brouillon est à l'écran : statut « Brouillon » seul.
  final bool draft;

  /// « 18 séances / semaine · 7 enseignants », sous 600 reçus.
  final String? counts;

  const ClassTimetableIdentity({
    super.key,
    required this.view,
    required this.draft,
    this.counts,
  });

  /// Une couleur stable par classe, quel que soit l'ordre de chargement.
  static Color markerOf(String classroomId) => AcademicsClassVisual.forIndex(
    classroomId.codeUnits.fold(0, (a, b) => a + b),
  ).accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final classroom = view.classroom;
    final room = classroom.room;
    final trace = TimetableTrace.of(context, view.header, draft: draft);
    final counts = this.counts;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: AppDimensions.timetableIdentityMarkerWidth,
          height: AppDimensions.timetableIdentityMarkerHeight,
          decoration: BoxDecoration(
            color: markerOf(classroom.classroomId),
            borderRadius: AppRadius.brSm,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    classroom.name,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.bleuProfond,
                    ),
                  ),
                  if (room != null)
                    Text(
                      room,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (draft)
                    StatusBadge.draft(
                      label: l10n.classTimetableDraft,
                      size: StatusBadgeSize.small,
                    )
                  else if (view.header?.isPublished ?? false)
                    StatusBadge.paid(
                      label: l10n.classTimetablePublished,
                      size: StatusBadgeSize.small,
                    ),
                ],
              ),
              if (trace != null)
                Text(
                  trace,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              if (counts != null)
                Text(
                  counts,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.bleuArdoise,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
