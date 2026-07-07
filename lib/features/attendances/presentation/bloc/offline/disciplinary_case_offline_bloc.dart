import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/create_disciplinary_case_offline_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/get_offline_disciplinary_cases_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/update_disciplinary_case_offline_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_state.dart';

/// BLoC offline-first des cas disciplinaires (DF-1/2) : lecture du grand-livre
/// local, création (régime A, id client + outbox CREATE) et traitement
/// (régime C, LWW status/sanction + outbox UPDATE), exposant l'état pending-sync.
class DisciplinaryCaseOfflineBloc
    extends Bloc<DisciplinaryCaseOfflineEvent, DisciplinaryCaseOfflineState> {
  final CreateDisciplinaryCaseOfflineUseCase _createCase;
  final UpdateDisciplinaryCaseOfflineUseCase _updateCase;
  final GetOfflineDisciplinaryCasesUseCase _getCases;

  DisciplinaryCaseOfflineBloc({
    required CreateDisciplinaryCaseOfflineUseCase createCase,
    required UpdateDisciplinaryCaseOfflineUseCase updateCase,
    required GetOfflineDisciplinaryCasesUseCase getCases,
  }) : _createCase = createCase,
       _updateCase = updateCase,
       _getCases = getCases,
       super(const DisciplinaryOfflineInitial()) {
    on<LoadOfflineDisciplinaryCases>(_onLoad);
    on<CreateOfflineDisciplinaryCase>(_onCreate);
    on<UpdateOfflineDisciplinaryCase>(_onUpdate);
  }

  Future<void> _onLoad(
    LoadOfflineDisciplinaryCases event,
    Emitter<DisciplinaryCaseOfflineState> emit,
  ) async {
    emit(const DisciplinaryOfflineLoading());
    final result = await _getCases(
      studentId: event.studentId,
      academicYearId: event.academicYearId,
    );
    emit(
      result.fold(
        (f) => DisciplinaryOfflineError(_map(f)),
        (cases) => DisciplinaryOfflineCasesLoaded(cases),
      ),
    );
  }

  Future<void> _onCreate(
    CreateOfflineDisciplinaryCase event,
    Emitter<DisciplinaryCaseOfflineState> emit,
  ) async {
    emit(const DisciplinaryOfflineSaving());
    final result = await _createCase(
      studentId: event.studentId,
      studentFirstName: event.studentFirstName,
      studentLastName: event.studentLastName,
      studentMiddleName: event.studentMiddleName,
      studentGender: event.studentGender,
      disciplinaryCaseDate: event.disciplinaryCaseDate,
      academicYearId: event.academicYearId,
      title: event.title,
      content: event.content,
      category: event.category,
      severity: event.severity,
      sanction: event.sanction,
    );
    emit(
      result.fold(
        (f) => DisciplinaryOfflineError(_map(f)),
        (created) => DisciplinaryOfflineCasePendingSync(created),
      ),
    );
  }

  Future<void> _onUpdate(
    UpdateOfflineDisciplinaryCase event,
    Emitter<DisciplinaryCaseOfflineState> emit,
  ) async {
    emit(const DisciplinaryOfflineSaving());
    final result = await _updateCase(
      caseId: event.caseId,
      status: event.status,
      sanction: event.sanction,
      expectedVersion: event.expectedVersion,
    );
    emit(
      result.fold(
        (f) => DisciplinaryOfflineError(_map(f)),
        (_) => const DisciplinaryOfflineCaseUpdated(),
      ),
    );
  }

  String _map(Failure failure) => switch (failure) {
    StorageFailure() => 'Erreur d\'accès à la base locale.',
    ConflictFailure() => 'Version périmée : ce cas a été modifié ailleurs.',
    _ => 'Une erreur est survenue.',
  };
}
