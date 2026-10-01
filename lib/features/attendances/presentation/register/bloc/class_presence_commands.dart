import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_justification.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark_editor.dart';
import 'package:school_app_flutter/core/presence/domain/presence_rules.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_day.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_line.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_month.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/register/class_presence_repository.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/register/class_presence_use_cases.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_notice.dart';

/// Les gestes de l'appel, sans état : chacun construit la marque cohérente
/// (l'éditeur commun), l'écrit, et rend ce que l'écran annonce — `null` quand
/// il n'y a rien à dire.
///
/// - Tant que l'appel n'est pas validé, une touche va au **brouillon**.
/// - Un appel validé refuse tout geste, sauf « Justifier » : la
///   justification après coup renvoie l'appel aussitôt, sans le rouvrir
///   (décision 9 — sur un jour révolu, elle reste sous `attendance.write`).
/// - Un mois clôturé refuse tout.
class ClassPresenceCommands {
  final SaveClassPresenceMarksUseCase _save;
  final ValidateClassPresenceDayUseCase _validate;
  final ReopenClassPresenceDayUseCase _reopen;
  final RetryClassPresenceDayUseCase _retry;
  final CloseClassPresenceMonthUseCase _close;
  final DateTime Function() _now;

  const ClassPresenceCommands({
    required SaveClassPresenceMarksUseCase save,
    required ValidateClassPresenceDayUseCase validate,
    required ReopenClassPresenceDayUseCase reopen,
    required RetryClassPresenceDayUseCase retry,
    required CloseClassPresenceMonthUseCase close,
    DateTime Function() now = DateTime.now,
  }) : _save = save,
       _validate = validate,
       _reopen = reopen,
       _retry = retry,
       _close = close,
       _now = now;

  /// Un toucher sur une carte : le statut suivant du cycle.
  Future<ClassPresenceNotice?> cycle(
    ClassPresenceDay day,
    ClassPresenceLine line,
  ) => choose(day, line, PresenceRules.nextInCycle(line.status));

  /// Un choix direct (vue liste). Retoucher le statut actif l'efface.
  Future<ClassPresenceNotice?> choose(
    ClassPresenceDay day,
    ClassPresenceLine line,
    PresenceStatus status,
  ) {
    if (status == line.status) return clear(day, line);
    return _edit(
      day,
      line,
      (editor) => editor.mark(line.mark, status, ClockTime.of(_now())),
    );
  }

  Future<ClassPresenceNotice?> clear(
    ClassPresenceDay day,
    ClassPresenceLine line,
  ) => _edit(
    day,
    line,
    (editor) => editor.clear(line.mark),
    done: ClassPresenceNotice(
      ClassPresenceNoticeKind.cleared,
      name: line.student.fullName,
    ),
  );

  Future<ClassPresenceNotice?> setArrival(
    ClassPresenceDay day,
    ClassPresenceLine line,
    ClockTime arrival,
  ) => _edit(day, line, (editor) => editor.setArrival(line.mark, arrival));

  /// Pose (ou retire, [justification] `null`) une justification. Sur un
  /// appel validé, l'appel repart aussitôt.
  Future<ClassPresenceNotice?> justify(
    ClassPresenceDay day,
    ClassPresenceLine line,
    PresenceJustification<AbsenceReason>? justification,
  ) async {
    final done = ClassPresenceNotice(
      justification == null
          ? ClassPresenceNoticeKind.justificationRemoved
          : ClassPresenceNoticeKind.justified,
      name: line.student.fullName,
    );
    if (day.monthClosed) {
      return const ClassPresenceNotice(ClassPresenceNoticeKind.monthFrozen);
    }
    final changed = _editor(day).justify(line.mark, justification);
    if (changed == line.mark) return null;
    if (!day.validated) {
      return _outcome(await _saveMark(day, line, changed), done);
    }
    final lines = [
      for (final current in day.lines)
        current.student.id == line.student.id
            ? current.withMark(changed)
            : current,
    ];
    return _outcome(await _validate(_key(day), lines), done);
  }

  /// Marque tous les « à pointer » présents à l'heure de début.
  Future<ClassPresenceNotice?> markRemainingPresent(
    ClassPresenceDay day,
  ) async {
    final frozen = _frozen(day);
    if (frozen != null) return frozen;
    final marks = _remaining(day);
    if (marks.isEmpty) return null;
    return _outcome(
      await _save(_key(day), marks),
      ClassPresenceNotice(
        ClassPresenceNoticeKind.remainingMarked,
        count: marks.length,
      ),
    );
  }

  /// Valide l'appel : les « à pointer » partent présents à l'heure de début
  /// (décision 2 — l'appel envoyé ne connaît pas « à pointer »).
  Future<ClassPresenceNotice?> validate(
    ClassPresenceDay day, {
    required String classroomName,
  }) async {
    final frozen = _frozen(day);
    if (frozen != null) return frozen;
    if (day.lines.any((line) => line.blocksResend)) {
      return const ClassPresenceNotice(
        ClassPresenceNoticeKind.unsupportedReason,
      );
    }
    final remaining = _remaining(day);
    final lines = [
      for (final line in day.lines)
        if (remaining[line.student.id] case final mark?)
          line.withMark(mark)
        else
          line,
    ];
    return _outcome(
      await _validate(_key(day), lines),
      ClassPresenceNotice(
        ClassPresenceNoticeKind.validated,
        name: classroomName,
      ),
    );
  }

  /// Rouvre un appel validé ; impossible dans un mois clôturé.
  Future<ClassPresenceNotice?> reopen(ClassPresenceDay day) async {
    if (day.monthClosed) {
      return const ClassPresenceNotice(ClassPresenceNoticeKind.monthFrozen);
    }
    if (day.lines.any((line) => line.blocksResend)) {
      return const ClassPresenceNotice(
        ClassPresenceNoticeKind.unsupportedReason,
      );
    }
    return _outcome(
      await _reopen(_key(day), day.lines),
      const ClassPresenceNotice(ClassPresenceNoticeKind.reopened),
    );
  }

  /// Remet en file l'envoi refusé de l'appel.
  Future<ClassPresenceNotice?> retry(ClassPresenceDay day) async => _outcome(
    await _retry(_key(day)),
    const ClassPresenceNotice(ClassPresenceNoticeKind.retried),
  );

  /// Clôt le mois de la classe — irréversible depuis la tablette.
  Future<ClassPresenceNotice?> closeMonth(
    ClassPresenceMonth month, {
    required String classroomName,
  }) async {
    if (month.closed) {
      return const ClassPresenceNotice(ClassPresenceNoticeKind.monthFrozen);
    }
    return _outcome(
      await _close((
        classroomId: month.classroomId,
        academicYearId: month.academicYearId,
        month: month.month,
      )),
      ClassPresenceNotice(
        ClassPresenceNoticeKind.monthClosed,
        name: classroomName,
        month: month.month,
      ),
    );
  }

  Future<ClassPresenceNotice?> _edit(
    ClassPresenceDay day,
    ClassPresenceLine line,
    PresenceMark<AbsenceReason> Function(PresenceMarkEditor editor) change, {
    ClassPresenceNotice? done,
  }) async {
    final frozen = _frozen(day);
    if (frozen != null) return frozen;
    final changed = change(_editor(day));
    if (changed == line.mark) return null;
    return _outcome(await _saveMark(day, line, changed), done);
  }

  Future<Either<Failure, Unit>> _saveMark(
    ClassPresenceDay day,
    ClassPresenceLine line,
    PresenceMark<AbsenceReason> mark,
  ) => _save(_key(day), {line.student.id: mark});

  /// Les « à pointer », présents à l'heure de début.
  Map<String, PresenceMark<AbsenceReason>> _remaining(ClassPresenceDay day) {
    final editor = _editor(day);
    return {
      for (final line in day.lines)
        if (line.status == PresenceStatus.none)
          line.student.id: editor.setArrival(line.mark, day.schedule.start),
    };
  }

  static PresenceMarkEditor _editor(ClassPresenceDay day) =>
      PresenceMarkEditor(PresenceRules(day.schedule));

  static ClassPresenceNotice? _frozen(ClassPresenceDay day) {
    if (day.monthClosed) {
      return const ClassPresenceNotice(ClassPresenceNoticeKind.monthFrozen);
    }
    if (day.validated) {
      return const ClassPresenceNotice(ClassPresenceNoticeKind.dayFrozen);
    }
    return null;
  }

  static ClassDayKey _key(ClassPresenceDay day) => (
    classroomId: day.classroomId,
    academicYearId: day.academicYearId,
    day: day.day,
  );

  static ClassPresenceNotice? _outcome(
    Either<Failure, Unit> result,
    ClassPresenceNotice? done,
  ) => result.fold(
    (_) => const ClassPresenceNotice(ClassPresenceNoticeKind.writeFailed),
    (_) => done,
  );
}
