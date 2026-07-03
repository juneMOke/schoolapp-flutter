import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/note_saisie_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/saisie_draft_controller.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_notation_atoms.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/absence_toggle.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/saisie_numpad.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

part 'saisie_focus_parts.dart';

/// Saisie en mode Focus (spec §9) : un élève à la fois, carte centrée. Fil de
/// progression cliquable, note en grand, pavé numérique, absences, « Effacer ·
/// en attente », navigation Précédent / Suivant. Clavier physique mappé.
class SaisieFocus extends StatefulWidget {
  final List<NoteEleve> students;
  final SaisieDraftController draft;
  final bool inputsEnabled;

  const SaisieFocus({
    super.key,
    required this.students,
    required this.draft,
    required this.inputsEnabled,
  });

  @override
  State<SaisieFocus> createState() => _SaisieFocusState();
}

class _SaisieFocusState extends State<SaisieFocus> {
  int _index = 0;
  final FocusNode _keyboardNode = FocusNode();

  int get _total => widget.students.length;

  @override
  void dispose() {
    _keyboardNode.dispose();
    super.dispose();
  }

  void _go(int i) {
    setState(() => _index = i.clamp(0, _total - 1));
  }

  void _next() {
    if (_index < _total - 1) setState(() => _index++);
  }

  void _prev() {
    if (_index > 0) setState(() => _index--);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _prev();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _next();
      return KeyEventResult.handled;
    }
    if (!widget.inputsEnabled) return KeyEventResult.ignored;
    final id = widget.students[_index].studentId;
    if (key == LogicalKeyboardKey.backspace) {
      widget.draft.backspaceNote(id);
      return KeyEventResult.handled;
    }
    final ch = event.character;
    if (ch != null && ch.length == 1) {
      if (RegExp(r'[0-9]').hasMatch(ch)) {
        widget.draft.appendNoteChar(id, ch);
        return KeyEventResult.handled;
      }
      if (ch == ',' || ch == '.') {
        widget.draft.appendNoteChar(id, ',');
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _keyboardNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: AnimatedBuilder(
        animation: widget.draft,
        builder: (context, _) => _card(context),
      ),
    );
  }

  Widget _card(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final index = _index.clamp(0, _total - 1);
    final student = widget.students[index];
    final id = student.studentId;
    final draft = widget.draft;
    final absence = draft.absenceOf(id);
    final statut = draft.statutFor(id);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.brCard,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProgressThread(draft: draft, current: index, onTap: _go),
              const SizedBox(height: AppSpacing.md),
              _Identity(student: student, position: index + 1, total: _total),
              const SizedBox(height: AppSpacing.md),
              _BigNote(draft: draft, id: id),
              const SizedBox(height: AppSpacing.md),
              if (absence == null)
                SaisieNumpad(
                  enabled: widget.inputsEnabled,
                  onChar: (ch) => draft.appendNoteChar(id, ch),
                  onBackspace: () => draft.backspaceNote(id),
                )
              else
                _AbsencePlaceholder(statut: statut),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  AbsenceToggle(
                    selected: absence,
                    enabled: widget.inputsEnabled,
                    size: 44,
                    onToggle: (a) => draft.toggleAbsence(id, a),
                  ),
                  const Spacer(),
                  EteeloButton.ghost(
                    label: l10n.evalFocusClear,
                    icon: Icons.backspace_outlined,
                    onPressed: widget.inputsEnabled
                        ? () => draft.clearEntry(id)
                        : null,
                    fullWidth: false,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _NavRow(
                index: index,
                total: _total,
                onPrev: _prev,
                onNext: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
