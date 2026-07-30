import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/get_local_attendance_rate_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/get_student_attendance_stats_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/load_daily_attendance_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/record_daily_attendance_offline_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_state.dart';

/// BLoC offline-first du module Présence : liste d'appel locale (AF-1),
/// confirmation d'appel pending-sync (AF-2) et taux dérivé localement (AF-3).
class AttendanceOfflineBloc
    extends Bloc<AttendanceOfflineEvent, AttendanceOfflineState> {
  final LoadDailyAttendanceUseCase _loadDaily;
  final RecordDailyAttendanceOfflineUseCase _recordDaily;
  final GetLocalAttendanceRateUseCase _getRate;
  final GetStudentAttendanceStatsUseCase _getStudentStats;

  AttendanceOfflineBloc({
    required LoadDailyAttendanceUseCase loadDaily,
    required RecordDailyAttendanceOfflineUseCase recordDaily,
    required GetLocalAttendanceRateUseCase getRate,
    required GetStudentAttendanceStatsUseCase getStudentStats,
  }) : _loadDaily = loadDaily,
       _recordDaily = recordDaily,
       _getRate = getRate,
       _getStudentStats = getStudentStats,
       super(const AttendanceOfflineInitial()) {
    on<LoadDailyAttendanceRequested>(_onLoadDaily);
    on<RecordDailyAttendanceRequested>(_onRecordDaily);
    on<LoadLocalRateRequested>(_onLoadRate);
    // Sérialisé (`sequential`) : le calcul enchaîne plusieurs await (lecture
    // transferts, résolution classe, comptage sessions, absences détaillées) —
    // sans ça, un changement rapide de période (double-tap) traiterait 2
    // requêtes en concurrence et la plus lente pourrait écraser l'état avec un
    // résultat périmé après la plus récente (pas de transformer par défaut =
    // traitement concurrent, cf. package:bloc).
    on<LoadStudentStatsRequested>(
      _onLoadStudentStats,
      transformer: _sequential(),
    );
  }

  /// Traite les événements un par un (asyncExpand) — pas de dépendance externe.
  static EventTransformer<E> _sequential<E>() =>
      (events, mapper) => events.asyncExpand(mapper);

  Future<void> _onLoadDaily(
    LoadDailyAttendanceRequested event,
    Emitter<AttendanceOfflineState> emit,
  ) async {
    emit(const AttendanceOfflineLoading());
    final result = await _loadDaily(
      classroomId: event.classroomId,
      date: event.date,
      academicYearId: event.academicYearId,
    );
    emit(
      result.fold(
        (f) => AttendanceOfflineError(_map(f)),
        (daily) => AttendanceOfflineLoaded(daily),
      ),
    );
  }

  Future<void> _onRecordDaily(
    RecordDailyAttendanceRequested event,
    Emitter<AttendanceOfflineState> emit,
  ) async {
    emit(const AttendanceOfflineRecording());
    final result = await _recordDaily(
      classroomId: event.classroomId,
      date: event.date,
      academicYearId: event.academicYearId,
      updates: event.updates,
    );
    emit(
      result.fold(
        (f) => AttendanceOfflineError(_map(f)),
        // Écriture locale confirmée + mise en file outbox : pending-sync.
        (_) => const AttendanceOfflinePendingSync(),
      ),
    );
  }

  Future<void> _onLoadRate(
    LoadLocalRateRequested event,
    Emitter<AttendanceOfflineState> emit,
  ) async {
    emit(const AttendanceOfflineLoading());
    final result = await _getRate(
      classroomId: event.classroomId,
      date: event.date,
      academicYearId: event.academicYearId,
    );
    emit(
      result.fold(
        (f) => AttendanceOfflineError(_map(f)),
        (rate) => AttendanceOfflineRateLoaded(rate),
      ),
    );
  }

  Future<void> _onLoadStudentStats(
    LoadStudentStatsRequested event,
    Emitter<AttendanceOfflineState> emit,
  ) async {
    emit(const AttendanceOfflineLoading());
    final result = await _getStudentStats(
      studentId: event.studentId,
      academicYearId: event.academicYearId,
      period: event.period,
      reference: event.reference,
    );
    emit(
      result.fold(
        (f) => AttendanceOfflineError(_map(f)),
        (stats) => AttendanceOfflineStatsLoaded(stats),
      ),
    );
  }

  String _map(Failure failure) => switch (failure) {
    StorageFailure() => 'Erreur d\'accès à la base locale.',
    _ => 'Une erreur est survenue.',
  };
}
