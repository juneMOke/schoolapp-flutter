import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_validation.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/audience/announcement_reach_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/audience/audience_referential_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/audience/audience_mode_picker.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/audience/classroom_selector.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/audience/level_selector.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/audience/overdue_selector.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/audience/reach_box.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/audience/student_selector.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/editor_section_card.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Section 2 — à qui. Les destinataires réels sont les tuteurs des élèves
/// ciblés : un message par couple (tuteur, élève).
class AudienceSection extends StatelessWidget {
  final AnnouncementEditorState state;
  final List<SchoolLevelGroupBundle> groups;

  const AudienceSection({super.key, required this.state, required this.groups});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<AnnouncementEditorCubit>();
    final locked = state.inputLocked;
    final selections = state.selections;
    return EditorSectionCard(
      number: 2,
      title: l10n.communicationSectionAudience,
      subtitle: l10n.communicationSectionAudienceHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AudienceModePicker(
            value: selections.mode,
            onChanged: locked ? null : cubit.setAudienceMode,
          ),
          const SizedBox(height: AppSpacing.lg),
          _Selector(state: state, groups: groups, locked: locked),
          if (state.hasIssueOn(AnnouncementField.audience)) ...[
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              liveRegion: true,
              child: Text(
                _emptyMessage(l10n, selections.mode),
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          BlocBuilder<AnnouncementReachCubit, AnnouncementReachState>(
            builder: (context, reach) => ReachBox(
              state: reach,
              onRetry: context.read<AnnouncementReachCubit>().retry,
            ),
          ),
        ],
      ),
    );
  }

  static String _emptyMessage(AppLocalizations l10n, AudienceMode mode) =>
      switch (mode) {
        AudienceMode.levels => l10n.communicationAudienceNeedLevel,
        AudienceMode.classrooms => l10n.communicationAudienceNeedClassroom,
        AudienceMode.students => l10n.communicationAudienceNeedStudent,
        _ => l10n.communicationReachInvalid,
      };
}

class _Selector extends StatelessWidget {
  final AnnouncementEditorState state;
  final List<SchoolLevelGroupBundle> groups;
  final bool locked;

  const _Selector({
    required this.state,
    required this.groups,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<AnnouncementEditorCubit>();
    final selections = state.selections;
    final referential = context.watch<AudienceReferentialCubit>().state;
    return switch (selections.mode) {
      AudienceMode.school => Text(
        l10n.communicationAudienceSchoolHint,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      AudienceMode.levels => LevelSelector(
        groups: groups,
        selected: selections.levelIds,
        onToggle: locked ? null : cubit.toggleLevel,
      ),
      AudienceMode.classrooms => ClassroomSelector(
        groups: groups,
        referential: referential.referential,
        selected: selections.classroomIds,
        onToggle: locked ? null : cubit.toggleClassroom,
        onToggleLevel: locked ? null : cubit.toggleClassrooms,
      ),
      AudienceMode.students => StudentSelector(
        selected: selections.students,
        onAdd: locked ? null : cubit.addStudent,
        onRemove: locked ? null : cubit.removeStudent,
      ),
      AudienceMode.overdue => OverdueSelector(
        selections: selections,
        fees: referential.referential.fees,
        titles: context.watch<FeeSectionTitlesCubit>().state,
        onFee: locked ? null : cubit.setOverdueFee,
        onDays: locked ? null : cubit.setOverdueDays,
      ),
    };
  }
}
