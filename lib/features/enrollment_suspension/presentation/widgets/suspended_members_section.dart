import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_dashed_border.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspended_member.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_candidate.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_target.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/suspension_flow.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspension_start_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La section « Élèves désactivés » de la composition des classes : hors
/// effectif, chacun avec sa classe d'origine et « Réactiver ».
class SuspendedMembersSection extends StatelessWidget {
  final List<SuspendedMember> members;

  /// Nom de la classe d'origine d'un membre.
  final String Function(String classroomId) classLabelOf;

  const SuspendedMembersSection({
    super.key,
    required this.members,
    required this.classLabelOf,
  });

  static const double _tileMinWidth = 280;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloDashedContainer(
      backgroundColor: AppColors.surfaceRaised,
      borderColor: AppColors.suspendedBorder,
      borderRadius: AppRadius.brCard,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.suspendedSurface,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.suspendedSectionTitle(members.length),
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.suspendedInk,
                  ),
                ),
                Text(
                  l10n.suspendedSectionSubtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.suspendedInk,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = (constraints.maxWidth / _tileMinWidth)
                    .floor()
                    .clamp(1, 4);
                final width =
                    (constraints.maxWidth - AppSpacing.md * (columns - 1)) /
                    columns;
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final m in members)
                      SizedBox(
                        width: width,
                        child: Opacity(
                          opacity: 0.85,
                          child: _Tile(
                            member: m,
                            classLabel: classLabelOf(m.classroomId),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final SuspendedMember member;
  final String classLabel;

  const _Tile({required this.member, required this.classLabel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = member.suspension;
    final candidate = SuspensionCandidate(
      target: SuspensionTarget(
        enrollmentId: s.enrollmentId,
        studentId: s.studentId,
        academicYearId: s.academicYearId,
      ),
      lastName: member.lastName,
      middleName: member.middleName,
      firstName: member.firstName,
      classLabel: classLabel,
    );
    return Row(
      children: [
        PersonAvatar(
          firstName: member.firstName,
          lastName: member.lastName,
          personId: s.studentId,
          studentPhotoOf: s.studentId,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                candidate.familyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                l10n.suspendedMemberLine(
                  member.firstName,
                  classLabel,
                  s.suspendedAt,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SuspensionGate(
          child: EteeloButton.secondary(
            label: l10n.reactivationConfirm,
            fullWidth: false,
            onPressed: () =>
                SuspensionFlow.reactivate(context, [candidate], suspension: s),
          ),
        ),
      ],
    );
  }
}
