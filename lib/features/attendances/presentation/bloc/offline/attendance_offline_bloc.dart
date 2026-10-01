import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/get_student_attendance_stats_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_state.dart';

/// BLoC offline-first de l'assiduité d'un élève (onglet Présence du dossier) :
/// sa synthèse calculée en local sur une période. L'appel d'une classe a son
/// propre écran (`ClassPresenceCubit`).
class AttendanceOfflineBloc
    extends Bloc<AttendanceOfflineEvent, AttendanceOfflineState> {
  final GetStudentAttendanceStatsUseCase _getStudentStats;

  AttendanceOfflineBloc({
    required GetStudentAttendanceStatsUseCase getStudentStats,
  }) : _getStudentStats = getStudentStats,
       super(const AttendanceOfflineInitial()) {
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
