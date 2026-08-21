import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/domain/repositories/academic_year_context_repository.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';

part 'academic_year_context_event.dart';
part 'academic_year_context_state.dart';

/// Contexte académique **courant** — remplace `BootstrapCurrentYearBloc`
/// (module `bootstrap` supprimé). Lecture 100% locale du référentiel
/// offline ; pull en ligne déclenché par le repository si absent en local.
///
/// Sert AUSSI de gate de navigation (`blocksNavigation`/`hasBlockingFailure`,
/// consommés par `app_router.dart`/`SplashPage`) quand l'instance est résolue
/// depuis `main.dart` post-auth. Les feature scopes en résolvent chacune une
/// instance indépendante (`registerFactory`, self-sufficient — même principe
/// que les `PullHandler` du `PullCoordinator`) pour leur propre lecture.
class AcademicYearContextBloc
    extends Bloc<AcademicYearContextEvent, AcademicYearContextState> {
  final AcademicYearContextRepository _repository;

  /// Anti-course (revue adversariale) : sans `EventTransformer`, deux
  /// événements du même bloc s'exécutent en CONCURRENCE — un logout suivi
  /// d'un relogin rapide (ou deux `Requested` rapprochés) peut laisser une
  /// résolution périmée écraser l'état après coup (fuite de contexte
  /// inter-école, voire `sessionExpired` erroné → logout de la nouvelle
  /// session). Chaque `_onRequested` capture la génération courante avant son
  /// `await` et abandonne silencieusement (ni cache ni emit) si une requête
  /// plus récente — ou un reset — a pris la main entretemps. Même idiome que
  /// `EnrollmentLocalListBloc._loadGeneration`.
  int _requestGeneration = 0;

  AcademicYearContextBloc({required AcademicYearContextRepository repository})
    : _repository = repository,
      super(const AcademicYearContextState.initial()) {
    on<AcademicYearContextRequested>(_onRequested);
    on<AcademicYearContextRetryRequested>(_onRequested);
    on<AcademicYearContextSchoolLevelSplitPatched>(_onSchoolLevelSplitPatched);
    on<AcademicYearContextResetRequested>(_onResetRequested);
  }

  Future<void> _onRequested(
    AcademicYearContextEvent event,
    Emitter<AcademicYearContextState> emit,
  ) async {
    final generation = ++_requestGeneration;
    emit(
      state.copyWith(
        status: AcademicYearContextLoadStatus.loading,
        sessionExpired: false,
        insufficientPermissions: false,
      ),
    );
    final result = await _repository.loadCurrentContext();
    if (generation != _requestGeneration) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AcademicYearContextLoadStatus.failure,
          errorMessage: failure.message,
          // Le logout n'est prononcé QUE si l'échec de session bloque
          // réellement : sans contexte en main, l'utilisateur resterait coincé
          // sur le splash. Avec des données locales déjà résolues (cas du
          // rafraîchissement au retour réseau), un 401 isolé ne prouve rien sur
          // la session : il peut venir d'un jeton pas encore renouvelé ou d'une
          // couche intermédiaire. Le verdict de session appartient à la chaîne
          // d'auth (refresh du contrat + révocation `userVersion`), pas à un
          // pull de référentiel — sinon un incident réseau éjecte l'agent de
          // son écran.
          sessionExpired: _isSessionFailure(failure) && state.context == null,
          insufficientPermissions: failure is UnauthorizedFailure,
        ),
      ),
      (context) => emit(
        state.copyWith(
          status: AcademicYearContextLoadStatus.success,
          context: context,
          errorMessage: null,
          sessionExpired: false,
          insufficientPermissions: false,
        ),
      ),
    );
  }

  void _onResetRequested(
    AcademicYearContextResetRequested event,
    Emitter<AcademicYearContextState> emit,
  ) {
    _requestGeneration++; // invalide toute résolution en vol avant ce reset
    emit(const AcademicYearContextState.initial());
  }

  /// Seul le **401** dit que la session n'est plus valide côté serveur →
  /// `main.dart` déclenchera un logout.
  ///
  /// Le **403** en est délibérément exclu (ADR-014 §4) : depuis que les
  /// permissions sont appliquées, n'importe quel point d'entrée peut refuser un
  /// compte parfaitement authentifié. Le lire comme une session morte
  /// renverrait l'utilisateur à l'écran de connexion, où il se reconnecterait
  /// pour être éjecté de nouveau — une boucle dont il ne peut pas sortir, sur
  /// un incident qui ne concerne pas sa session mais ses droits.
  bool _isSessionFailure(Failure failure) =>
      failure is InvalidCredentialsFailure;

  Future<void> _onSchoolLevelSplitPatched(
    AcademicYearContextSchoolLevelSplitPatched event,
    Emitter<AcademicYearContextState> emit,
  ) async {
    final current = state.context;
    if (current == null) return;

    await _repository.markSchoolLevelSplit(event.schoolLevelId);

    final patched = AcademicYearContext(
      academicYear: current.academicYear,
      schoolLevelGroups: [
        for (final bundle in current.schoolLevelGroups)
          SchoolLevelGroupBundle(
            group: bundle.group,
            levels: [
              for (final level in bundle.levels)
                level.id == event.schoolLevelId
                    ? SchoolLevel(
                        id: level.id,
                        name: level.name,
                        code: level.code,
                        displayOrder: level.displayOrder,
                        splitIntoClassrooms: true,
                      )
                    : level,
            ],
          ),
      ],
    );

    emit(state.copyWith(context: patched));
  }
}
