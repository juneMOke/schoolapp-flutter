import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_chip.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/attendance_justification.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/helpers/justification_labels.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/widgets/justification_card_actions.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/widgets/justification_card_notice.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/widgets/justification_status_tag.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une justification d'absence : qui, quel jour, pourquoi, ce que le parent
/// en dit, et les gestes de l'école.
class JustificationCard extends StatelessWidget {
  final AttendanceJustification justification;
  final bool attachmentAvailable;
  final VoidCallback onOpenAttachment;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const JustificationCard({
    super.key,
    required this.justification,
    required this.attachmentAvailable,
    required this.onOpenAttachment,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final j = justification;
    final submitted = JustificationLabels.date(dates, j.submittedAt);
    final decided = JustificationLabels.date(dates, j.decidedAt);
    final block = j.awaitsDecision ? j.acceptBlock : null;
    final refusal = j.awaitsDecision ? j.refusal : null;
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border.all(color: AppColors.border),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  JustificationLabels.student(l10n, j),
                  style: AppTypography.titleSmall,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              JustificationStatusTag(justification: j),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (j.classroomName case final name?)
                EteeloChip(icon: Icons.class_outlined, label: name),
              EteeloChip(
                icon: Icons.event_busy_outlined,
                label: PresenceLabels.longDay(dates, j.attendanceDate),
              ),
              EteeloChip(
                icon: Icons.help_outline,
                label: j.reason.getDisplayName(l10n),
              ),
            ],
          ),
          if (j.note case final note? when note.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _Quote(label: l10n.justificationParentNote, text: note),
          ],
          if (j.decisionNote case final note? when note.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _Quote(label: l10n.justificationSchoolNote, text: note),
          ],
          if (submitted != null || decided != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              [
                if (submitted != null) l10n.justificationSubmittedOn(submitted),
                if (decided != null) l10n.justificationDecidedOn(decided),
              ].join(' · '),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
          if (block != null) ...[
            const SizedBox(height: AppSpacing.md),
            JustificationCardNotice(
              message: JustificationLabels.acceptBlock(l10n, block),
            ),
          ],
          if (refusal != null) ...[
            const SizedBox(height: AppSpacing.md),
            JustificationCardNotice(
              message: l10n.justificationRefusalNotice(refusal),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          JustificationCardActions(
            justification: j,
            attachmentAvailable: attachmentAvailable,
            onOpenAttachment: onOpenAttachment,
            onAccept: onAccept,
            onReject: onReject,
          ),
        ],
      ),
    );
  }
}

class _Quote extends StatelessWidget {
  final String label;
  final String text;

  const _Quote({required this.label, required this.text});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(text, style: AppTypography.bodyMedium),
    ],
  );
}
