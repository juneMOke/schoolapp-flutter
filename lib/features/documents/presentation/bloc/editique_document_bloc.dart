import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_server_detail.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_account_statement_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_enrollment_attestation_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_financial_clearance_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_note_perception_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_payment_receipt_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/restitute_document_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/student_year_document_params.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_error_type.dart';

part 'editique_document_event.dart';
part 'editique_document_state.dart';

/// Émission d'une pièce d'éditique, une à la fois.
///
/// Portée volontairement étroite : une instance ne porte **qu'une** pièce
/// vivante. Le catalogue de l'élève en instancie donc une par ligne — c'est ce
/// qui donne à chaque ligne son état local `idle | busy | error` indépendant,
/// et qui garantit qu'un échec sur le quitus ne balaie pas l'attestation
/// affichée à côté.
///
/// Les cinq pièces que le front sait émettre y sont câblées. Le bulletin (BU)
/// reste hors périmètre : il exige `classroomId` + `periodeScolaireId`,
/// inatteignables depuis un élève, et son émission n'est pas idempotente.
class EditiqueDocumentBloc
    extends Bloc<EditiqueDocumentEvent, EditiqueDocumentState> {
  final EmitEnrollmentAttestationUseCase _emitEnrollmentAttestationUseCase;
  final EmitNotePerceptionUseCase _emitNotePerceptionUseCase;
  final EmitPaymentReceiptUseCase _emitPaymentReceiptUseCase;
  final EmitAccountStatementUseCase _emitAccountStatementUseCase;
  final EmitFinancialClearanceUseCase _emitFinancialClearanceUseCase;
  final RestituteDocumentUseCase _restituteDocumentUseCase;

  EditiqueDocumentBloc({
    required EmitEnrollmentAttestationUseCase emitEnrollmentAttestationUseCase,
    required EmitNotePerceptionUseCase emitNotePerceptionUseCase,
    required EmitPaymentReceiptUseCase emitPaymentReceiptUseCase,
    required EmitAccountStatementUseCase emitAccountStatementUseCase,
    required EmitFinancialClearanceUseCase emitFinancialClearanceUseCase,
    required RestituteDocumentUseCase restituteDocumentUseCase,
  }) : _emitEnrollmentAttestationUseCase = emitEnrollmentAttestationUseCase,
       _emitNotePerceptionUseCase = emitNotePerceptionUseCase,
       _emitPaymentReceiptUseCase = emitPaymentReceiptUseCase,
       _emitAccountStatementUseCase = emitAccountStatementUseCase,
       _emitFinancialClearanceUseCase = emitFinancialClearanceUseCase,
       _restituteDocumentUseCase = restituteDocumentUseCase,
       super(const EditiqueDocumentState()) {
    on<EditiqueEnrollmentAttestationRequested>(
      (event, emit) => _run(
        emit,
        EditiqueDocumentType.enrollmentAttestation,
        () => _emitEnrollmentAttestationUseCase(
          EmitEnrollmentAttestationParams(
            enrollmentId: event.enrollmentId,
            studentId: event.studentId,
            academicYearId: event.academicYearId,
          ),
        ),
      ),
    );

    on<EditiqueNotePerceptionRequested>(
      (event, emit) => _run(
        emit,
        EditiqueDocumentType.notePerception,
        () => _emitNotePerceptionUseCase(
          StudentYearDocumentParams(
            studentId: event.studentId,
            academicYearId: event.academicYearId,
          ),
        ),
      ),
    );

    on<EditiquePaymentReceiptRequested>(
      (event, emit) => _run(
        emit,
        EditiqueDocumentType.paymentReceipt,
        () => _emitPaymentReceiptUseCase(
          EmitPaymentReceiptParams(
            paymentId: event.paymentId,
            studentId: event.studentId,
            academicYearId: event.academicYearId,
          ),
        ),
      ),
    );

    on<EditiqueAccountStatementRequested>(
      (event, emit) => _run(
        emit,
        EditiqueDocumentType.accountStatement,
        () => _emitAccountStatementUseCase(
          StudentYearDocumentParams(
            studentId: event.studentId,
            academicYearId: event.academicYearId,
          ),
        ),
      ),
    );

    on<EditiqueFinancialClearanceRequested>(
      (event, emit) => _run(
        emit,
        EditiqueDocumentType.financialClearance,
        () => _emitFinancialClearanceUseCase(
          StudentYearDocumentParams(
            studentId: event.studentId,
            academicYearId: event.academicYearId,
          ),
        ),
      ),
    );

    on<EditiqueDocumentRestitutionRequested>(
      (event, emit) => _run(
        emit,
        event.type,
        () => _restituteDocumentUseCase(
          RestituteDocumentParams(
            type: event.type,
            documentId: event.documentId,
            documentNumber: event.documentNumber,
            studentId: event.studentId,
            academicYearId: event.academicYearId,
          ),
        ),
      ),
    );
  }

  /// Corps commun à l'émission et à la restitution : même verrou, même état,
  /// même traduction d'échec. Ce qui les distingue — un aller-retour serveur
  /// obligatoire d'un côté, une copie locale de l'autre — a été tranché plus
  /// bas, dans le repository.
  Future<void> _run(
    Emitter<EditiqueDocumentState> emit,
    EditiqueDocumentType type,
    Future<Either<Failure, EditiqueDocument>> Function() request,
  ) async {
    // Verrou anti-double-envoi : une demande déjà en vol ne doit jamais être
    // doublée. Sur une pièce non archivée, un second appel brûlerait un second
    // numéro de séquence côté serveur.
    if (state.status == EditiqueDocumentStatus.loading) return;

    emit(
      state.copyWith(
        status: EditiqueDocumentStatus.loading,
        type: type,
        clearDocument: true,
        clearError: true,
      ),
    );

    final result = await request();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: EditiqueDocumentStatus.failure,
          errorType: _mapFailureToErrorType(failure),
          // Le message du serveur est souvent la seule information exploitable
          // (« Aucune charge pour l'élève ») ; l'anatomie, elle, ne sait dire
          // que la famille d'erreur. `null` quand le serveur n'a rien dit.
          serverDetail: EditiqueServerDetail.of(failure),
        ),
      ),
      (document) => emit(
        state.copyWith(
          status: EditiqueDocumentStatus.success,
          document: document,
          clearError: true,
        ),
      ),
    );
  }

  EditiqueErrorType _mapFailureToErrorType(Failure failure) {
    return switch (failure) {
      NetworkFailure() => EditiqueErrorType.network,
      UncertainOutcomeFailure() => EditiqueErrorType.uncertain,
      InvalidCredentialsFailure() => EditiqueErrorType.sessionExpired,
      UnauthorizedFailure() => EditiqueErrorType.forbidden,
      NotFoundFailure() => EditiqueErrorType.notFound,
      ValidationFailure() => EditiqueErrorType.invalid,
      ConflictFailure() => EditiqueErrorType.invalid,
      _ => EditiqueErrorType.server,
    };
  }
}
