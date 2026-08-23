import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/models/attendance_editable_row.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_reason_grid.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_row_editors.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Saisie **un absent à la fois**, pour la passe des motifs.
///
/// ## Pourquoi ce n'est pas le Focus des notes
///
/// Le Focus de la saisie de notes existe pour entrer une quarantaine de nombres
/// vite : grand nombre, pavé numérique, clavier physique mappé, on ne quitte
/// jamais le pavé. Rien de tout cela ne se transpose. Une note est un nombre ;
/// une absence est un booléen, un motif et une note libre.
///
/// Surtout, le flux dominant de l'appel est « tout le monde est là sauf
/// trois », déjà servi par « Marquer tous présents ». Un Focus sur l'effectif
/// entier imposerait quarante passages pour trois absences — il serait **plus
/// lent** que la liste qu'il remplace.
///
/// D'où le cadrage : ce mode n'itère **que sur les absents**, et n'a de sens
/// que pour la passe des motifs — celle qui bloque aujourd'hui
/// l'enregistrement tant qu'un motif manque.
///
/// ## Ce qu'il ne possède pas
///
/// Aucun brouillon à lui. Le Focus des notes partage un `SaisieDraftController`
/// avec son tableau ; ici l'état vit déjà dans le BLoC, et la carte émet les
/// **mêmes événements** que les lignes de la liste. Les deux modes restent donc
/// d'accord par construction, sans rien à synchroniser.
class AttendanceFocusMode extends StatefulWidget {
  /// Les absents, dans l'ordre de la liste.
  final List<AttendanceEditableRow> rows;

  const AttendanceFocusMode({super.key, required this.rows});

  @override
  State<AttendanceFocusMode> createState() => _AttendanceFocusModeState();
}

class _AttendanceFocusModeState extends State<AttendanceFocusMode> {
  int _index = 0;
  final FocusNode _keyboardNode = FocusNode();

  @override
  void dispose() {
    _keyboardNode.dispose();
    super.dispose();
  }

  int get _total => widget.rows.length;

  /// ⚠️ La liste des absents **rétrécit sous les pieds** de ce widget : rendre
  /// un motif ne retire pas l'élève, mais le repasser présent, si. L'index doit
  /// donc être borné à chaque rendu et non seulement à la navigation, sinon un
  /// `rows[_index]` sort de la liste au premier retrait.
  int get _safeIndex => _total == 0 ? 0 : _index.clamp(0, _total - 1);

  void _go(int i) => setState(() => _index = i.clamp(0, _total - 1));
  void _next() {
    if (_safeIndex < _total - 1) _go(_safeIndex + 1);
  }

  void _prev() {
    if (_safeIndex > 0) _go(_safeIndex - 1);
  }

  /// Avance d'un élève dès qu'un motif est posé — c'est la passe des motifs
  /// qui est le sujet du mode, et la faire en un tap par élève est son intérêt.
  ///
  /// ⚠️ **Le compromis est assumé et il a un coût** : la note libre de la carte
  /// devient inatteignable dans la foulée du motif. C'est acceptable parce que
  /// la note est l'exception — et parce que revenir coûte **un tap** sur le fil
  /// de progression, qui est juste au-dessus. Un mauvais motif se rattrape par
  /// le même chemin.
  ///
  /// Depuis le dernier absent, [_next] ne bouge pas — il porte déjà le garde,
  /// et `_go` borne par-dessus. Une troisième condition ici serait une
  /// redondance qu'aucun test ne peut distinguer : la mutation qui la retire
  /// laisse la suite verte, parce que le comportement est identique.
  void _advanceAfterReason() => _next();

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    // Les seules touches capturées sont celles de NAVIGATION : la saisie du
    // motif et de la note reste au clavier logiciel des champs, qui doivent
    // continuer de recevoir tout le reste.
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _prev();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _next();
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (_total == 0) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final index = _safeIndex;
    final row = widget.rows[index];
    final bloc = context.read<AttendanceBloc>();

    return Focus(
      focusNode: _keyboardNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProgressThread(rows: widget.rows, current: index, onTap: _go),
                const SizedBox(height: AppDimensions.spacingM),
                _Identity(row: row, position: index + 1, total: _total),
                const SizedBox(height: AppDimensions.spacingM),
                // Grande cible plutôt que dropdown : c'est le geste que le
                // mode existe pour économiser — un menu rouvert à chaque élève
                // coûte deux taps là où une cible en coûte un.
                AttendanceReasonGrid(
                  selected: row.absenceReason,
                  onSelected: (reason) {
                    bloc.add(
                      AttendanceAbsenceReasonChanged(
                        studentId: row.studentId,
                        absenceReason: reason,
                      ),
                    );
                    _advanceAfterReason();
                  },
                ),
                const SizedBox(height: AppDimensions.spacingS),
                AttendanceAbsenceNoteField(
                  value: row.absenceReasonNote,
                  enabled: true,
                  onChanged: (note) => bloc.add(
                    AttendanceAbsenceNoteChanged(
                      studentId: row.studentId,
                      note: note,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                Row(
                  children: [
                    EteeloButton.secondary(
                      label: l10n.attendanceFocusPrevious,
                      onPressed: index > 0 ? _prev : null,
                      fullWidth: false,
                    ),
                    const Spacer(),
                    EteeloButton.primary(
                      label: l10n.attendanceFocusNext,
                      onPressed: index < _total - 1 ? _next : null,
                      fullWidth: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Le fil de progression : une pastille par absent, verte dès qu'un motif est
/// posé. C'est ce qui rend visible « il en reste deux » sans quitter la carte.
class _ProgressThread extends StatelessWidget {
  final List<AttendanceEditableRow> rows;
  final int current;
  final ValueChanged<int> onTap;

  const _ProgressThread({
    required this.rows,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = 0; i < rows.length; i++)
          _ThreadDot(
            done: rows[i].absenceReason != null,
            isCurrent: i == current,
            onTap: () => onTap(i),
          ),
      ],
    );
  }
}

class _ThreadDot extends StatelessWidget {
  final bool done;
  final bool isCurrent;
  final VoidCallback onTap;

  const _ThreadDot({
    required this.done,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.success : AppColors.danger;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color.withValues(alpha: isCurrent ? 0.9 : 0.28),
          borderRadius: BorderRadius.circular(4),
          border: isCurrent ? Border.all(color: color, width: 2) : null,
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final AttendanceEditableRow row;
  final int position;
  final int total;

  const _Identity({
    required this.row,
    required this.position,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final middle = (row.studentMiddleName ?? '').trim();
    final fullName = middle.isEmpty
        ? '${row.studentLastName} ${row.studentFirstName}'
        : '${row.studentLastName} $middle ${row.studentFirstName}';

    return Row(
      children: [
        StudentAvatar(
          firstName: row.studentFirstName,
          lastName: row.studentLastName,
          studentId: row.studentId,
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(fullName, style: AppTextStyles.bodyStrong),
              Text(
                '$position / $total',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
