import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_account_statement_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_payment_receipt_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/student_year_document_params.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_error_type.dart';

part 'editique_document_event.dart';
part 'editique_document_state.dart';

/// Émission d'une pièce d'éditique, une à la fois.
///
/// Portée volontairement étroite : une instance sert **une** visionneuse. Les
/// pièces restantes (attestation, note de perception, quitus) rejoindront ce
/// BLoC quand leurs écrans existeront — rien n'est câblé d'avance.
class EditiqueDocumentBloc
    extends Bloc<EditiqueDocumentEvent, EditiqueDocumentState> {
  final EmitPaymentReceiptUseCase _emitPaymentReceiptUseCase;
  final EmitAccountStatementUseCase _emitAccountStatementUseCase;

  EditiqueDocumentBloc({
    required EmitPaymentReceiptUseCase emitPaymentReceiptUseCase,
    required EmitAccountStatementUseCase emitAccountStatementUseCase,
  }) : _emitPaymentReceiptUseCase = emitPaymentReceiptUseCase,
       _emitAccountStatementUseCase = emitAccountStatementUseCase,
       super(const EditiqueDocumentState()) {
    on<EditiquePaymentReceiptRequested>(
      (event, emit) => _emit(
        emit,
        EditiqueDocumentType.paymentReceipt,
        () => _emitPaymentReceiptUseCase(
          EmitPaymentReceiptParams(paymentId: event.paymentId),
        ),
      ),
    );

    on<EditiqueAccountStatementRequested>(
      (event, emit) => _emit(
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
  }

  Future<void> _emit(
    Emitter<EditiqueDocumentState> emit,
    EditiqueDocumentType type,
    Future<Either<Failure, EditiqueDocument>> Function() request,
  ) async {
    // Verrou anti-double-envoi : une émission déjà en vol ne doit jamais être
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
