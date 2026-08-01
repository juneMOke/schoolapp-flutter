import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/get_classroom_grid_usecase.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/get_my_timetable_usecase.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/schedule_error_type.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/timetable_event.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/timetable_state.dart';

/// BLoC de **lecture** de l'emploi du temps (cœur de l'app enseignant).
///
/// Ne déclenche rien au montage : attend un [TimetableRequested] (emploi du
/// temps de l'enseignant connecté) ou un [ClassroomGridRequested] (grille d'une
/// classe). Les cases `null` de la matrice sont des créneaux libres — jamais
/// traitées comme une erreur.
class TimetableBloc extends Bloc<TimetableEvent, TimetableState> {
  final GetMyTimetableUseCase _getMyTimetable;
  final GetClassroomGridUseCase _getClassroomGrid;

  /// Année du dernier [TimetableRequested] servi — permet à
  /// [TimetableRefreshRequested] de relire sans que l'appelant (le
  /// `FeatureScope`, qui ne résout pas l'année) ait à la connaître. Remise à
  /// `null` par [ClassroomGridRequested] : l'écran n'affiche alors plus « mon »
  /// emploi du temps, un rafraîchissement silencieux l'écraserait.
  String? _lastAcademicYearId;

  /// Numéro de la dernière lecture ÉMISE (toutes lectures confondues). Les
  /// handlers `on<…>` d'événements de types différents s'exécutent en
  /// **parallèle** dans bloc : une relecture déclenchée par un pull peut donc
  /// se terminer avant la lecture initiale partie plus tôt sur un cache encore
  /// vide — et cette dernière écraserait alors la grille fraîche par une grille
  /// vide, exactement le bug que le rafraîchissement corrige. Chaque lecture
  /// capture ce numéro au départ et n'émet que si elle est toujours la plus
  /// récente : le dernier ORDRE donné gagne, quel que soit l'ordre d'arrivée.
  int _readGeneration = 0;

  TimetableBloc({
    required GetMyTimetableUseCase getMyTimetable,
    required GetClassroomGridUseCase getClassroomGrid,
  }) : _getMyTimetable = getMyTimetable,
       _getClassroomGrid = getClassroomGrid,
       super(const TimetableState()) {
    on<TimetableRequested>(_onTimetableRequested);
    on<TimetableRefreshRequested>(_onTimetableRefreshRequested);
    on<ClassroomGridRequested>(_onClassroomGridRequested);
  }

  Future<void> _onTimetableRequested(
    TimetableRequested event,
    Emitter<TimetableState> emit,
  ) async {
    _lastAcademicYearId = event.academicYearId;
    final generation = ++_readGeneration;
    emit(
      state.copyWith(
        status: TimetableStatus.loading,
        errorType: ScheduleErrorType.none,
      ),
    );

    final result = await _getMyTimetable(event.academicYearId);
    if (generation != _readGeneration) return; // lecture dépassée

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: TimetableStatus.failure,
          errorType: _mapFailureToErrorType(failure),
        ),
      ),
      (timetable) => emit(
        state.copyWith(
          status: TimetableStatus.success,
          timetable: timetable,
          errorType: ScheduleErrorType.none,
        ),
      ),
    );
  }

  /// Relecture silencieuse après un pull : ni état de chargement (le squelette
  /// clignoterait sur un écran déjà rempli), ni bascule en erreur (une grille
  /// correcte à l'écran ne doit pas être remplacée par un message d'échec à
  /// cause d'une relecture opportuniste — l'utilisateur n'a rien demandé). Un
  /// succès, lui, écrase l'état courant, y compris une erreur précédente.
  Future<void> _onTimetableRefreshRequested(
    TimetableRefreshRequested event,
    Emitter<TimetableState> emit,
  ) async {
    final academicYearId = _lastAcademicYearId;
    if (academicYearId == null) return;

    final generation = ++_readGeneration;
    final result = await _getMyTimetable(academicYearId);
    if (generation != _readGeneration) return; // lecture dépassée

    result.fold(
      (_) {}, // échec silencieux : on conserve ce qui est affiché
      (timetable) => emit(
        state.copyWith(
          status: TimetableStatus.success,
          timetable: timetable,
          errorType: ScheduleErrorType.none,
        ),
      ),
    );
  }

  Future<void> _onClassroomGridRequested(
    ClassroomGridRequested event,
    Emitter<TimetableState> emit,
  ) async {
    _lastAcademicYearId = null;
    final generation = ++_readGeneration;
    emit(
      state.copyWith(
        status: TimetableStatus.loading,
        errorType: ScheduleErrorType.none,
      ),
    );

    final result = await _getClassroomGrid(
      GetClassroomGridParams(
        classroomId: event.classroomId,
        academicYearId: event.academicYearId,
      ),
    );
    if (generation != _readGeneration) return; // lecture dépassée

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: TimetableStatus.failure,
          errorType: _mapFailureToErrorType(failure),
        ),
      ),
      (timetable) => emit(
        state.copyWith(
          status: TimetableStatus.success,
          timetable: timetable,
          errorType: ScheduleErrorType.none,
        ),
      ),
    );
  }

  ScheduleErrorType _mapFailureToErrorType(
    Failure failure,
  ) => switch (failure) {
    NetworkFailure() => ScheduleErrorType.network,
    NotFoundFailure() => ScheduleErrorType.notFound,
    ValidationFailure() => ScheduleErrorType.validation,
    // Convention projet (cf. interceptor Dio) : HTTP 403 -> UnauthorizedFailure
    // -> forbidden ; HTTP 401 -> InvalidCredentialsFailure -> invalidCredentials.
    UnauthorizedFailure() => ScheduleErrorType.forbidden,
    InvalidCredentialsFailure() => ScheduleErrorType.invalidCredentials,
    ConflictFailure() => ScheduleErrorType.conflict,
    ServerFailure() => ScheduleErrorType.server,
    StorageFailure() => ScheduleErrorType.storage,
    AuthFailure() => ScheduleErrorType.auth,
    _ => ScheduleErrorType.unknown,
  };
}
