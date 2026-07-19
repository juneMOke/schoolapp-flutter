import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/add_disciplinary_comment_offline_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/create_disciplinary_case_offline_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/get_disciplinary_comment_counts_offline_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/get_disciplinary_comments_offline_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/get_disciplinary_freshness_offline_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/get_offline_disciplinary_cases_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/update_disciplinary_case_offline_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_state.dart';

/// BLoC offline-first des cas disciplinaires (DF-1/2/B) : lecture du grand-livre
/// local (avec nombre de commentaires), création (régime A), traitement (régime
/// C, LWW) et fil de commentaires append-only (DF-B).
///
/// Les usecases de commentaires sont **optionnels** : les points d'appel qui
/// n'en ont pas besoin (tests de base) construisent le BLoC sans eux.
class DisciplinaryCaseOfflineBloc
    extends Bloc<DisciplinaryCaseOfflineEvent, DisciplinaryCaseOfflineState> {
  final CreateDisciplinaryCaseOfflineUseCase _createCase;
  final UpdateDisciplinaryCaseOfflineUseCase _updateCase;
  final GetOfflineDisciplinaryCasesUseCase _getCases;
  final GetDisciplinaryCommentCountsOfflineUseCase? _getCommentCounts;
  final GetDisciplinaryCommentsOfflineUseCase? _getComments;
  final AddDisciplinaryCommentOfflineUseCase? _addComment;
  final GetDisciplinaryFreshnessOfflineUseCase? _getFreshness;

  DisciplinaryCaseOfflineBloc({
    required CreateDisciplinaryCaseOfflineUseCase createCase,
    required UpdateDisciplinaryCaseOfflineUseCase updateCase,
    required GetOfflineDisciplinaryCasesUseCase getCases,
    GetDisciplinaryCommentCountsOfflineUseCase? getCommentCounts,
    GetDisciplinaryCommentsOfflineUseCase? getComments,
    AddDisciplinaryCommentOfflineUseCase? addComment,
    GetDisciplinaryFreshnessOfflineUseCase? getFreshness,
  }) : _createCase = createCase,
       _updateCase = updateCase,
       _getCases = getCases,
       _getCommentCounts = getCommentCounts,
       _getComments = getComments,
       _addComment = addComment,
       _getFreshness = getFreshness,
       super(const DisciplinaryOfflineInitial()) {
    on<LoadOfflineDisciplinaryCases>(_onLoad);
    // Les mutations sont **sérialisées** (`sequential`) : deux écritures
    // concurrentes (double-tap, ajout de commentaire pendant un traitement)
    // liraient l'état local en même temps et l'une figerait un payload d'agrégat
    // périmé — le coalescing outbox (dernier écrivain gagne) perdrait alors une
    // écriture (commentaire orphelin). En file, chaque mutation relit l'état à
    // jour avant de re-figer.
    on<CreateOfflineDisciplinaryCase>(_onCreate, transformer: _sequential());
    on<UpdateOfflineDisciplinaryCase>(_onUpdate, transformer: _sequential());
    on<AddOfflineDisciplinaryComment>(
      _onAddComment,
      transformer: _sequential(),
    );
    on<LoadOfflineDisciplinaryComments>(_onLoadComments);
  }

  /// Traite les événements un par un (asyncExpand) — pas de dépendance externe.
  static EventTransformer<E> _sequential<E>() =>
      (events, mapper) => events.asyncExpand(mapper);

  Future<void> _onLoad(
    LoadOfflineDisciplinaryCases event,
    Emitter<DisciplinaryCaseOfflineState> emit,
  ) async {
    emit(const DisciplinaryOfflineLoading());
    final result = await _getCases(
      studentId: event.studentId,
      academicYearId: event.academicYearId,
    );
    await result.fold((f) async => emit(DisciplinaryOfflineError(_map(f))), (
      cases,
    ) async {
      final counts = await _loadCounts(cases.map((c) => c.id).toList());
      final freshness = await _getFreshness?.call();
      emit(
        DisciplinaryOfflineCasesLoaded(
          cases,
          commentCounts: counts,
          freshness: freshness,
        ),
      );
    });
  }

  Future<Map<String, int>> _loadCounts(List<String> caseIds) async {
    final usecase = _getCommentCounts;
    if (usecase == null || caseIds.isEmpty) return const {};
    final result = await usecase(caseIds: caseIds);
    return result.fold((_) => const {}, (counts) => counts);
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

  Future<void> _onLoadComments(
    LoadOfflineDisciplinaryComments event,
    Emitter<DisciplinaryCaseOfflineState> emit,
  ) async {
    final usecase = _getComments;
    if (usecase == null) return;
    emit(const DisciplinaryOfflineLoading());
    final result = await usecase(caseId: event.caseId);
    emit(
      result.fold(
        (f) => DisciplinaryOfflineError(_map(f)),
        (comments) => DisciplinaryOfflineCommentsLoaded(event.caseId, comments),
      ),
    );
  }

  Future<void> _onAddComment(
    AddOfflineDisciplinaryComment event,
    Emitter<DisciplinaryCaseOfflineState> emit,
  ) async {
    final addUsecase = _addComment;
    final getUsecase = _getComments;
    if (addUsecase == null || getUsecase == null) return;
    emit(const DisciplinaryOfflineSaving());
    final result = await addUsecase(
      caseId: event.caseId,
      content: event.content,
      authorName: event.authorName,
    );
    await result.fold((f) async => emit(DisciplinaryOfflineError(_map(f))), (
      _,
    ) async {
      // Append-only : on recharge le fil pour refléter le nouveau commentaire.
      final reloaded = await getUsecase(caseId: event.caseId);
      emit(
        reloaded.fold(
          (f) => DisciplinaryOfflineError(_map(f)),
          (comments) =>
              DisciplinaryOfflineCommentsLoaded(event.caseId, comments),
        ),
      );
    });
  }

  String _map(Failure failure) => switch (failure) {
    StorageFailure() => 'Erreur d\'accès à la base locale.',
    ConflictFailure() => 'Version périmée : ce cas a été modifié ailleurs.',
    _ => 'Une erreur est survenue.',
  };
}
