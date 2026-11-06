import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_options.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_request.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/bloc/level_correction_gesture_cubit.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/widgets/level_correction_refusal_l10n.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspension_notice.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que la modale corrige : l'inscription, et le niveau qu'elle porte.
class LevelCorrectionSubject {
  final String enrollmentId;
  final String studentId;
  final String academicYearId;
  final String fromSchoolLevelId;
  final String fromLevelName;

  const LevelCorrectionSubject({
    required this.enrollmentId,
    required this.studentId,
    required this.academicYearId,
    required this.fromSchoolLevelId,
    required this.fromLevelName,
  });
}

/// Modale « Corriger le niveau ». Se ferme sur `true` une fois le geste posé ;
/// reste ouverte, saisie conservée, en cas d'échec. Non fermable pendant
/// l'écriture.
class LevelCorrectionDialog extends StatefulWidget {
  final LevelCorrectionSubject subject;

  /// Les niveaux de l'année ; celui de départ n'est pas proposé.
  final List<LevelOption> levels;
  final LevelCorrectionClassrooms classrooms;

  static const int reasonMaxLength = 500;

  const LevelCorrectionDialog({
    super.key,
    required this.subject,
    required this.levels,
    required this.classrooms,
  });

  @override
  State<LevelCorrectionDialog> createState() => _LevelCorrectionDialogState();
}

class _LevelCorrectionDialogState extends State<LevelCorrectionDialog> {
  final TextEditingController _reason = TextEditingController();
  LevelOption? _level;
  String? _classroomId;

  @override
  void initState() {
    super.initState();
    _reason.addListener(_onReasonChanged);
  }

  @override
  void dispose() {
    _reason
      ..removeListener(_onReasonChanged)
      ..dispose();
    super.dispose();
  }

  void _onReasonChanged() => setState(() {});

  List<LevelOption> get _targets => [
    for (final l in widget.levels)
      if (l.id != widget.subject.fromSchoolLevelId) l,
  ];

  bool get _needsClassroom {
    final level = _level;
    return level != null && widget.classrooms.requiresClassroom(level.id);
  }

  bool get _canSubmit =>
      _level != null &&
      _reason.text.trim().isNotEmpty &&
      (!_needsClassroom || _classroomId != null);

  void _pickLevel(LevelOption? level) => setState(() {
    _level = level;
    // Une classe d'un autre niveau ne vaut plus rien : on la retire.
    _classroomId = null;
  });

  void _submit() {
    final level = _level;
    if (level == null || !_canSubmit) return;
    final subject = widget.subject;
    context.read<LevelCorrectionGestureCubit>().submit(
      LevelCorrectionRequest(
        enrollmentId: subject.enrollmentId,
        studentId: subject.studentId,
        academicYearId: subject.academicYearId,
        fromSchoolLevelId: subject.fromSchoolLevelId,
        toSchoolLevelId: level.id,
        toSchoolLevelGroupId: level.groupId,
        toClassroomId: _needsClassroom ? _classroomId : null,
        reason: _reason.text,
      ),
    );
  }

  String _problem(AppLocalizations l10n, LevelCorrectionGestureFailed state) =>
      switch (state.problem) {
        LevelCorrectionGestureProblem.alreadyPending =>
          l10n.levelCorrectionAlreadyPending,
        LevelCorrectionGestureProblem.refusedLocally =>
          l10n.levelCorrectionRefusalMessage(state.refusal?.wire),
        LevelCorrectionGestureProblem.writeFailed =>
          l10n.levelCorrectionWriteFailed,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<
      LevelCorrectionGestureCubit,
      LevelCorrectionGestureState
    >(
      listenWhen: (_, state) => state is LevelCorrectionGestureDone,
      listener: (context, _) => Navigator.of(context).pop(true),
      builder: (context, state) {
        final busy = state is LevelCorrectionGestureBusy;
        final VoidCallback? submit = busy || !_canSubmit ? null : _submit;
        final level = _level;
        final classrooms = level == null
            ? const <ClassroomOption>[]
            : widget.classrooms.ofLevel(level.id);
        return PopScope(
          canPop: !busy,
          child: EteeloFormDialog(
            onSubmit: submit,
            eyebrow: l10n.levelCorrectionDialogEyebrow,
            title: l10n.levelCorrectionDialogTitle,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SuspensionNotice(
                  lead: l10n.levelCorrectionCurrentLevel(
                    widget.subject.fromLevelName,
                  ),
                  body: l10n.levelCorrectionNoticeBody,
                ),
                const SizedBox(height: AppSpacing.lg),
                EteeloSelectInput<LevelOption>(
                  label: l10n.levelCorrectionTargetLevelLabel,
                  placeholder: l10n.levelCorrectionTargetLevelPlaceholder,
                  required: true,
                  value: level,
                  enabled: !busy,
                  items: [
                    for (final option in _targets)
                      EteeloSelectItem(
                        value: option,
                        label: l10n.levelCorrectionLevelOption(
                          option.groupName,
                          option.name,
                        ),
                      ),
                  ],
                  onChanged: _pickLevel,
                ),
                if (_needsClassroom) ...[
                  const SizedBox(height: AppSpacing.md),
                  EteeloSelectInput<String>(
                    label: l10n.levelCorrectionTargetClassroomLabel,
                    placeholder: l10n.levelCorrectionTargetClassroomPlaceholder,
                    required: true,
                    value: _classroomId,
                    enabled: !busy,
                    items: [
                      for (final c in classrooms)
                        EteeloSelectItem(value: c.id, label: c.name),
                    ],
                    onChanged: (id) => setState(() => _classroomId = id),
                  ),
                ] else if (level != null &&
                    widget.classrooms.isInClassroom) ...[
                  const SizedBox(height: AppSpacing.md),
                  SuspensionNotice(body: l10n.levelCorrectionNoClassroomNotice),
                ],
                const SizedBox(height: AppSpacing.md),
                EteeloTextInput(
                  controller: _reason,
                  label: l10n.levelCorrectionReasonLabel,
                  placeholder: l10n.levelCorrectionReasonHint,
                  required: true,
                  // Un texte libre : première lettre seulement.
                  capitalization: EteeloTextCapitalization.sentence,
                  enabled: !busy,
                  minLines: 2,
                  maxLines: 4,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      LevelCorrectionDialog.reasonMaxLength,
                    ),
                  ],
                ),
                if (state is LevelCorrectionGestureFailed)
                  SuspensionGestureError(message: _problem(l10n, state)),
              ],
            ),
            actions: [
              EteeloButton.ghost(
                label: l10n.levelCorrectionCancel,
                onPressed: busy ? null : () => Navigator.of(context).pop(),
                fullWidth: false,
              ),
              EteeloButton.primary(
                label: l10n.levelCorrectionConfirm,
                icon: Icons.swap_vert_rounded,
                isLoading: busy,
                loadingLabel: l10n.levelCorrectionBusy,
                onPressed: submit,
                fullWidth: false,
              ),
            ],
          ),
        );
      },
    );
  }
}
