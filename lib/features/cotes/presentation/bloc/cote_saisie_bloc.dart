import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/domain/repositories/cotes_repository.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_calculator.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_columns.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_input.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_edit_step.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_error_type.dart';

/// La source de vérité de l'écran. Tous les événements passent à la file, un à
/// la fois : l'ordre des frappes est garanti, et une relecture de la base ne
/// peut pas doubler une écriture en cours.
class CoteSaisieBloc extends Bloc<CoteSaisieEvent, CoteSaisieState> {
  final CotesRepository _repository;
  final CoteCalculator _calculator;

  /// Une cellule vient d'être posée. Le scope y branche l'enregistrement.
  void Function()? onCellWritten;

  String? _classroomId;
  CoteSaisieOpened? _lastOpened;
  Timer? _highlight;

  CoteSaisieBloc(
    this._repository, {
    CoteCalculator calculator = const CoteCalculator(),
    this.onCellWritten,
  }) : _calculator = calculator,
       super(const CoteSaisieIdle()) {
    on<CoteSaisieEvent>(
      _dispatch,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  String? get classroomId => _classroomId;

  Future<void> _dispatch(
    CoteSaisieEvent event,
    Emitter<CoteSaisieState> emit,
  ) => switch (event) {
    final CoteSaisieOpened e => _onOpened(e, emit),
    CoteSaisieRetried() => _onRetried(emit),
    CoteSaisieClosed() => _onClosed(emit),
    final CoteScopeChanged e => _onScope(e, emit),
    final CoteStudentSelected e => _onSelect(e.studentId, emit),
    final CoteStudentStepped e => _onStep(e, emit),
    final CoteCellEdited e => _onEdited(e, emit),
    final CoteRejectedDiscarded e => _onDiscarded(e, emit),
    CoteCellsRefreshed() => _onRefreshed(emit),
    CoteHighlightCleared() => _onHighlightCleared(emit),
  };

  Future<void> _onOpened(
    CoteSaisieOpened event,
    Emitter<CoteSaisieState> emit,
  ) async {
    _lastOpened = event;
    _classroomId = event.classroomId;
    emit(const CoteSaisieLoading());
    final result = await _repository.load(event.classroomId);
    result.fold((failure) => emit(_failureState(failure)), (snapshot) {
      emit(_readyOrEmpty(snapshot, event));
    });
  }

  /// Recharger garde l'élève et la portée à l'écran.
  Future<void> _onRetried(Emitter<CoteSaisieState> emit) {
    final last = _lastOpened;
    if (last == null) return Future.value();
    final s = state;
    return _onOpened(
      s is CoteSaisieReady
          ? CoteSaisieOpened(
              last.classroomId,
              scope: s.scope,
              eleveId: s.currentId,
            )
          : last,
      emit,
    );
  }

  CoteSaisieState _failureState(Failure failure) {
    if (failure is ApiValidationFailure &&
        failure.detailCode == 'GRID_NOT_ASSIGNED') {
      return const CoteSaisieEmpty(CoteEmptyReason.noCourses);
    }
    return CoteSaisieFailure(
      _errorType(failure),
      incidentCode: failure is ApiErrorDetails ? failure.incidentId : null,
    );
  }

  ResultatsErrorType _errorType(Failure failure) => switch (failure) {
    NetworkFailure() => ResultatsErrorType.network,
    NotFoundFailure() => ResultatsErrorType.notFound,
    ValidationFailure() => ResultatsErrorType.validation,
    UnauthorizedFailure() => ResultatsErrorType.forbidden,
    InvalidCredentialsFailure() => ResultatsErrorType.invalidCredentials,
    ServerFailure() => ResultatsErrorType.server,
    StorageFailure() => ResultatsErrorType.storage,
    AuthFailure() => ResultatsErrorType.auth,
    _ => ResultatsErrorType.unknown,
  };

  CoteSaisieState _readyOrEmpty(CoteSnapshot snapshot, CoteSaisieOpened event) {
    final classe = snapshot.classe;
    final cours = classe.allCours;
    if (classe.eleves.isEmpty) {
      return const CoteSaisieEmpty(CoteEmptyReason.noStudents);
    }
    if (cours.isEmpty) return const CoteSaisieEmpty(CoteEmptyReason.noCourses);
    final eleves = [...classe.eleves]..sort(_compareNames);
    final year = yearColumns(classe);
    var scope = event.scope ?? defaultScope(classe);
    var columns = columnsFor(classe, scope);
    if (columns.isEmpty) {
      scope = defaultScope(classe);
      columns = columnsFor(classe, scope);
    }
    final known = eleves.any((e) => e.studentId == event.eleveId);
    final cells = CoteCellTable.of(snapshot.cells);
    final calcs = _calcAll(eleves, cours, columns, cells);
    return CoteSaisieReady(
      classe: classe,
      cours: cours,
      eleves: eleves,
      cells: cells,
      scope: scope,
      year: year,
      columns: columns,
      currentId: known ? event.eleveId! : eleves.first.studentId,
      calcs: calcs,
      ranking: _calculator.rank(calcs),
      progress: _calculator.progress(calcs.values),
      fromCache: snapshot.fromCache,
    );
  }

  static int _compareNames(CoteEleve a, CoteEleve b) =>
      a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());

  Map<String, CoteEleveCalc> _calcAll(
    List<CoteEleve> eleves,
    List<CoteCours> cours,
    List<CoteColumn> columns,
    CoteCellTable cells,
  ) => {
    for (final eleve in eleves)
      eleve.studentId: _calculator.calcEleve(
        studentId: eleve.studentId,
        cours: cours,
        columns: columns,
        cells: cells,
      ),
  };

  Future<void> _onClosed(Emitter<CoteSaisieState> emit) async {
    _lastOpened = null;
    _classroomId = null;
    emit(const CoteSaisieIdle());
  }

  Future<void> _onScope(
    CoteScopeChanged event,
    Emitter<CoteSaisieState> emit,
  ) async {
    final s = state;
    if (s is! CoteSaisieReady) return;
    final columns = columnsFor(s.classe, event.scope);
    if (columns.isEmpty) return;
    emit(_recomputed(s, scope: event.scope, columns: columns));
  }

  CoteSaisieReady _recomputed(
    CoteSaisieReady s, {
    CoteScope? scope,
    List<CoteColumn>? columns,
    CoteCellTable? cells,
    Set<CoteCellKey>? changedKeys,
    int? changedNotice,
    int? changedCount,
  }) {
    final nextColumns = columns ?? s.columns;
    final nextCells = cells ?? s.cells;
    final calcs = _calcAll(s.eleves, s.cours, nextColumns, nextCells);
    return s.copyWith(
      scope: scope,
      columns: nextColumns,
      cells: nextCells,
      calcs: calcs,
      ranking: _calculator.rank(calcs),
      progress: _calculator.progress(calcs.values),
      changedKeys: changedKeys,
      changedNotice: changedNotice,
      changedCount: changedCount,
    );
  }

  Future<void> _onSelect(
    String studentId,
    Emitter<CoteSaisieState> emit,
  ) async {
    final s = state;
    if (s is! CoteSaisieReady || !s.calcs.containsKey(studentId)) return;
    emit(s.copyWith(currentId: studentId));
  }

  Future<void> _onStep(
    CoteStudentStepped event,
    Emitter<CoteSaisieState> emit,
  ) async {
    final s = state;
    if (s is! CoteSaisieReady) return;
    final next = s.currentIndex + event.delta;
    if (next < 0 || next >= s.eleves.length) return;
    emit(s.copyWith(currentId: s.eleves[next].studentId));
  }

  Future<void> _onEdited(
    CoteCellEdited event,
    Emitter<CoteSaisieState> emit,
  ) async {
    final s = state;
    final classroomId = _classroomId;
    if (s is! CoteSaisieReady || classroomId == null) return;
    final key = event.key;
    final column = s.year.where((c) => c.isInput && c.id == key.colonneId);
    final course = s.cours.where((c) => c.coursId == key.coursId);
    if (column.isEmpty || course.isEmpty) return;
    if (column.first.locked || !column.first.appliesTo(course.first)) return;

    final cell =
        s.cells.cell(key.studentId, key.coursId, key.colonneId) ??
        CoteCell(key: key);
    final input = parseCoteInput(event.raw, column.first.maxFor(course.first));
    final step = nextCoteEdit(_repository, cell, input, event.raw);
    if (step == null) return;

    emit(_withCell(s, step.cell, key.studentId));
    final result = await step.write(classroomId);
    result.fold(
      (_) {
        final current = state;
        if (current is CoteSaisieReady) {
          emit(current.copyWith(storageFailed: true));
        }
      },
      (_) {
        if (step.sends) onCellWritten?.call();
      },
    );
  }

  CoteSaisieReady _withCell(
    CoteSaisieReady s,
    CoteCell cell,
    String studentId,
  ) {
    final cells = s.cells.withCell(cell);
    final calcs = {
      ...s.calcs,
      studentId: _calculator.calcEleve(
        studentId: studentId,
        cours: s.cours,
        columns: s.columns,
        cells: cells,
      ),
    };
    return s.copyWith(
      cells: cells,
      calcs: calcs,
      ranking: _calculator.rank(calcs),
      progress: _calculator.progress(calcs.values),
    );
  }

  Future<void> _onDiscarded(
    CoteRejectedDiscarded event,
    Emitter<CoteSaisieState> emit,
  ) async {
    final s = state;
    if (s is! CoteSaisieReady) return;
    final result = await _repository.discardRejected(event.key);
    if (result.isRight()) await _onRefreshed(emit);
  }

  Future<void> _onRefreshed(Emitter<CoteSaisieState> emit) async {
    final classroomId = _classroomId;
    final s = state;
    if (s is! CoteSaisieReady || classroomId == null) return;
    final cells = await _repository.readCells(classroomId);
    final superseded = await _repository.takeSuperseded(classroomId);
    final changed = superseded.getOrElse(() => const <CoteCellKey>[]);
    cells.fold((_) {}, (list) {
      final current = state;
      if (current is! CoteSaisieReady) return;
      emit(
        _recomputed(
          current,
          cells: CoteCellTable.of(list),
          changedKeys: changed.isEmpty ? null : changed.toSet(),
          changedNotice: changed.isEmpty ? null : current.changedNotice + 1,
          changedCount: changed.isEmpty ? null : changed.length,
        ),
      );
    });
    if (changed.isNotEmpty) {
      _highlight?.cancel();
      _highlight = Timer(
        AppMotion.changedCellHighlight,
        () => add(const CoteHighlightCleared()),
      );
    }
  }

  Future<void> _onHighlightCleared(Emitter<CoteSaisieState> emit) async {
    final s = state;
    if (s is CoteSaisieReady) emit(s.copyWith(changedKeys: const {}));
  }

  @override
  Future<void> close() {
    _highlight?.cancel();
    return super.close();
  }
}
