import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_payment_allocations_from_student_charges_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_student_charges_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/update_student_charge_expected_amount_usecase.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/has_fee_grid_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/initialize_charges_use_case.dart';

part 'student_charges_event.dart';
part 'student_charges_state.dart';

class StudentChargesBloc
    extends Bloc<StudentChargesEvent, StudentChargesState> {
  final GetStudentChargesUseCase _getStudentChargesUseCase;
  final GetStudentChargesByAcademicYearUseCase
  _getStudentChargesByAcademicYearUseCase;
  final GetPaymentAllocationsFromStudentChargesUseCase
  _getPaymentAllocationsFromStudentChargesUseCase;
  final UpdateStudentChargeExpectedAmountUseCase
  _updateStudentChargeExpectedAmountUseCase;

  /// Génération FF5 des créances provisoires (flux brouillon du wizard).
  /// Optionnel : absent, [DraftStudentChargesRequested] dégrade en simple
  /// lecture (parité avec [StudentChargesRequested]).
  final InitializeChargesUseCase? _initializeChargesUseCase;

  /// Sonde de présence de la grille tarifaire (flux brouillon). Optionnelle :
  /// sans elle, le wizard se comporte comme avant — une liste vide passe pour
  /// « rien à payer ».
  final HasFeeGridUseCase? _hasFeeGridUseCase;

  StudentChargesBloc({
    required GetStudentChargesUseCase getStudentChargesUseCase,
    required GetStudentChargesByAcademicYearUseCase
    getStudentChargesByAcademicYearUseCase,
    required GetPaymentAllocationsFromStudentChargesUseCase
    getPaymentAllocationsFromStudentChargesUseCase,
    required UpdateStudentChargeExpectedAmountUseCase
    updateStudentChargeExpectedAmountUseCase,
    InitializeChargesUseCase? initializeChargesUseCase,
    HasFeeGridUseCase? hasFeeGridUseCase,
  }) : _getStudentChargesUseCase = getStudentChargesUseCase,
       _getStudentChargesByAcademicYearUseCase =
           getStudentChargesByAcademicYearUseCase,
       _getPaymentAllocationsFromStudentChargesUseCase =
           getPaymentAllocationsFromStudentChargesUseCase,
       _updateStudentChargeExpectedAmountUseCase =
           updateStudentChargeExpectedAmountUseCase,
       _initializeChargesUseCase = initializeChargesUseCase,
       _hasFeeGridUseCase = hasFeeGridUseCase,
       super(const StudentChargesState()) {
    on<StudentChargesRequested>(_onStudentChargesRequested);
    on<DraftStudentChargesRequested>(_onDraftStudentChargesRequested);
    on<StudentChargesByAcademicYearRequested>(
      _onStudentChargesByAcademicYearRequested,
      transformer: _sequential(),
    );
    on<StudentChargePaymentAllocationsRequested>(
      _onStudentChargePaymentAllocationsRequested,
    );
    on<StudentChargesDraftSaved>(_onStudentChargesDraftSaved);
    on<StudentChargeExpectedAmountUpdateRequested>(
      _onStudentChargeExpectedAmountUpdateRequested,
    );
  }

  /// Traite ces relectures une par une (`asyncExpand`) — pas de dépendance
  /// externe. Sans ça (traitement concurrent par défaut, cf. `package:bloc`),
  /// une relecture silencieuse déclenchée par un cycle abouti pourrait rendre
  /// AVANT la lecture initiale et se faire écraser par un résultat plus ancien.
  static EventTransformer<E> _sequential<E>() =>
      (events, mapper) => events.asyncExpand(mapper);

  Future<void> _onStudentChargesRequested(
    StudentChargesRequested event,
    Emitter<StudentChargesState> emit,
  ) async {
    emit(
      state.copyWith(
        status: StudentChargesStatus.loading,
        errorType: StudentChargesErrorType.none,
        updatingChargeId: null,
      ),
    );

    await _readCharges(
      studentId: event.studentId,
      levelId: event.levelId,
      emit: emit,
    );
  }

  /// Flux BROUILLON du wizard : génère les créances provisoires depuis la
  /// grille locale (FF5, idempotent), puis lit le grand-livre **scopé sur
  /// l'année du dossier** (année vide/NULL rattachée, comme la lecture ledger
  /// par année — sans quoi un RE additionnerait ses créances N-1). L'échec de
  /// la génération remonte en erreur (les frais affichés seraient sinon
  /// faussement vides) ; usecase absent → simple lecture.
  Future<void> _onDraftStudentChargesRequested(
    DraftStudentChargesRequested event,
    Emitter<StudentChargesState> emit,
  ) async {
    emit(
      state.copyWith(
        status: StudentChargesStatus.loading,
        errorType: StudentChargesErrorType.none,
        updatingChargeId: null,
      ),
    );

    final initialize = _initializeChargesUseCase;
    if (initialize != null && event.academicYearId.trim().isNotEmpty) {
      final initialized = await initialize(
        studentId: event.studentId,
        academicYearId: event.academicYearId,
        schoolLevelId: event.levelId,
        schoolLevelGroupId: event.schoolLevelGroupId,
      );
      final failure = initialized.fold((f) => f, (_) => null);
      if (failure != null) {
        emit(
          state.copyWith(
            status: StudentChargesStatus.failure,
            errorType: _mapFailureToErrorType(failure),
            updatingChargeId: null,
          ),
        );
        return;
      }
    }

    await _readCharges(
      studentId: event.studentId,
      levelId: event.levelId,
      scopedAcademicYearId: event.academicYearId,
      emit: emit,
    );

    // Créances vides : deux causes qui se ressemblent à l'écran et pas au
    // guichet. « Ce niveau n'a pas de frais » laisse poursuivre ; « la grille
    // n'est pas sur cet appareil » doit bloquer — sinon le secrétariat annonce
    // 0 F et la famille repart sans régler.
    //
    // Le cas est né de ce chantier : depuis que `feeTariffs` est nullable, un
    // profil sans `finance.grid.read` hydrate le référentiel en laissant
    // `ref_academic_years` peuplée (donc le wizard s'ouvre) et la grille vide.
    final probe = _hasFeeGridUseCase;
    if (probe == null ||
        state.status != StudentChargesStatus.success ||
        state.studentCharges.isNotEmpty ||
        event.academicYearId.trim().isEmpty) {
      // Le verdict d'une lecture précédente ne survit pas à celle-ci : ce bloc
      // sert plusieurs élèves et plusieurs niveaux au fil du wizard, et un
      // `true` conservé ferait porter à l'un l'absence de grille de l'autre.
      if (state.feeGridUnavailable) {
        emit(state.copyWith(feeGridUnavailable: false));
      }
      return;
    }
    final hasGrid = await probe(event.academicYearId);
    // Sonde en échec (base illisible) : on ne prétend pas savoir, et on ferme.
    emit(
      state.copyWith(
        feeGridUnavailable: hasGrid.fold((_) => true, (present) => !present),
      ),
    );
  }

  /// Lecture partagée (grand-livre local via le repo offline-first) — suppose
  /// l'état `loading` déjà émis par l'appelant. [scopedAcademicYearId] filtre
  /// le résultat sur une année (les créances à année vide restent rattachées).
  Future<void> _readCharges({
    required String studentId,
    required String levelId,
    String? scopedAcademicYearId,
    required Emitter<StudentChargesState> emit,
  }) async {
    final result = await _getStudentChargesUseCase(
      GetStudentChargesParams(studentId: studentId, levelId: levelId),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: StudentChargesStatus.failure,
          errorType: _mapFailureToErrorType(failure),
          updatingChargeId: null,
        ),
      ),
      (studentCharges) {
        // Vide-mais-non-null = "pas de scope" (comme null) : sinon le filtre
        // collapse en `c.academicYearId.isEmpty || c.academicYearId == ''`,
        // qui exclut TOUTE créance réelle (jamais vide en pratique).
        final scoped =
            (scopedAcademicYearId == null || scopedAcademicYearId.isEmpty)
            ? studentCharges
            : studentCharges
                  .where(
                    (c) =>
                        c.academicYearId.isEmpty ||
                        c.academicYearId == scopedAcademicYearId,
                  )
                  .toList(growable: false);
        emit(
          state.copyWith(
            status: StudentChargesStatus.success,
            studentCharges: scoped,
            errorType: StudentChargesErrorType.none,
            updatingChargeId: null,
          ),
        );
      },
    );
  }

  Future<void> _onStudentChargesByAcademicYearRequested(
    StudentChargesByAcademicYearRequested event,
    Emitter<StudentChargesState> emit,
  ) async {
    // Relecture silencieuse : aucun passage en `loading`. La lecture est locale
    // (le réseau, lui, revalide derrière sans être attendu) — faire clignoter un
    // skeleton par-dessus des lignes déjà justes coûterait plus qu'il n'informe.
    if (!event.silent) {
      emit(
        state.copyWith(
          status: StudentChargesStatus.loading,
          errorType: StudentChargesErrorType.none,
          updatingChargeId: null,
        ),
      );
    }

    final result = await _getStudentChargesByAcademicYearUseCase.call(
      GetStudentChargesByAcademicYearParams(
        studentId: event.studentId,
        academicYearId: event.academicYearId,
      ),
    );

    result.fold(
      (failure) {
        // Un échec de relecture silencieuse ne détruit pas ce qui est à
        // l'écran : l'utilisateur n'a rien demandé, il ne doit rien perdre.
        if (event.silent) return;
        emit(
          state.copyWith(
            status: StudentChargesStatus.failure,
            errorType: _mapFailureToErrorType(failure),
            updatingChargeId: null,
          ),
        );
      },
      // `updatingChargeId` laissé intact en silencieux : une édition de montant
      // en cours ne doit pas voir son verrou levé par un cycle de synchro.
      (studentCharges) => emit(
        event.silent
            ? state.copyWith(
                status: StudentChargesStatus.success,
                studentCharges: studentCharges,
                errorType: StudentChargesErrorType.none,
              )
            : state.copyWith(
                status: StudentChargesStatus.success,
                studentCharges: studentCharges,
                errorType: StudentChargesErrorType.none,
                updatingChargeId: null,
              ),
      ),
    );
  }

  Future<void> _onStudentChargePaymentAllocationsRequested(
    StudentChargePaymentAllocationsRequested event,
    Emitter<StudentChargesState> emit,
  ) async {
    emit(
      state.copyWith(
        allocationsStatus: StudentChargesStatus.loading,
        allocationsErrorType: StudentChargesErrorType.none,
      ),
    );

    final result = await _getPaymentAllocationsFromStudentChargesUseCase.call(
      GetPaymentAllocationsFromStudentChargesParams(chargeId: event.chargeId),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          allocationsStatus: StudentChargesStatus.failure,
          allocationsErrorType: _mapFailureToErrorType(failure),
        ),
      ),
      (allocations) {
        final nextAllocations = Map<String, List<PaymentAllocation>>.from(
          state.allocationsByChargeId,
        )..[event.chargeId] = allocations;

        emit(
          state.copyWith(
            allocationsStatus: StudentChargesStatus.success,
            allocationsByChargeId: nextAllocations,
            allocationsErrorType: StudentChargesErrorType.none,
          ),
        );
      },
    );
  }

  StudentChargesErrorType _mapFailureToErrorType(Failure failure) =>
      switch (failure) {
        NetworkFailure() => StudentChargesErrorType.network,
        NotFoundFailure() => StudentChargesErrorType.notFound,
        ValidationFailure() => StudentChargesErrorType.validation,
        UnauthorizedFailure() => StudentChargesErrorType.unauthorized,
        InvalidCredentialsFailure() =>
          StudentChargesErrorType.invalidCredentials,
        ServerFailure() => StudentChargesErrorType.server,
        StorageFailure() => StudentChargesErrorType.storage,
        AuthFailure() => StudentChargesErrorType.auth,
        _ => StudentChargesErrorType.unknown,
      };

  void _onStudentChargesDraftSaved(
    StudentChargesDraftSaved event,
    Emitter<StudentChargesState> emit,
  ) {
    emit(
      state.copyWith(
        status: StudentChargesStatus.success,
        studentCharges: event.studentCharges,
        errorType: StudentChargesErrorType.none,
        updatingChargeId: null,
      ),
    );
  }

  Future<void> _onStudentChargeExpectedAmountUpdateRequested(
    StudentChargeExpectedAmountUpdateRequested event,
    Emitter<StudentChargesState> emit,
  ) async {
    emit(
      state.copyWith(
        status: StudentChargesStatus.loading,
        errorType: StudentChargesErrorType.none,
        updatingChargeId: event.studentChargeId,
      ),
    );

    final result = await _updateStudentChargeExpectedAmountUseCase(
      UpdateStudentChargeExpectedAmountParams(
        studentChargeId: event.studentChargeId,
        studentId: event.studentId,
        expectedAmountInCents: event.expectedAmountInCents,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: StudentChargesStatus.failure,
          errorType: _mapFailureToErrorType(failure),
          updatingChargeId: event.studentChargeId,
        ),
      ),
      (updatedCharge) {
        final updatedCharges = state.studentCharges
            .map(
              (charge) =>
                  charge.id == updatedCharge.id ? updatedCharge : charge,
            )
            .toList(growable: false);

        emit(
          state.copyWith(
            status: StudentChargesStatus.success,
            studentCharges: updatedCharges,
            errorType: StudentChargesErrorType.none,
            updatingChargeId: null,
          ),
        );
      },
    );
  }
}
