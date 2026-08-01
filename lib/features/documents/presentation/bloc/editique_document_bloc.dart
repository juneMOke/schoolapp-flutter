import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_payment_receipt_use_case.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_error_type.dart';

part 'editique_document_event.dart';
part 'editique_document_state.dart';

/// Émission d'une pièce d'éditique, une à la fois.
///
/// Portée volontairement étroite : une instance sert **une** visionneuse. Les
/// autres pièces (attestation, note de perception, relevé, quitus) rejoindront
/// ce BLoC quand leurs écrans existeront — rien n'est câblé d'avance.
class EditiqueDocumentBloc
    extends Bloc<EditiqueDocumentEvent, EditiqueDocumentState> {
  final EmitPaymentReceiptUseCase _emitPaymentReceiptUseCase;

  EditiqueDocumentBloc({
    required EmitPaymentReceiptUseCase emitPaymentReceiptUseCase,
  }) : _emitPaymentReceiptUseCase = emitPaymentReceiptUseCase,
       super(const EditiqueDocumentState()) {
    on<EditiquePaymentReceiptRequested>(_onPaymentReceiptRequested);
  }

  Future<void> _onPaymentReceiptRequested(
    EditiquePaymentReceiptRequested event,
    Emitter<EditiqueDocumentState> emit,
  ) async {
    // Verrou anti-double-envoi : une émission déjà en vol ne doit jamais être
    // doublée. Sur une pièce non archivée, un second appel brûlerait un second
    // numéro de séquence côté serveur.
    if (state.status == EditiqueDocumentStatus.loading) return;

    emit(
      state.copyWith(
        status: EditiqueDocumentStatus.loading,
        type: EditiqueDocumentType.paymentReceipt,
        clearDocument: true,
        clearError: true,
      ),
    );

    final result = await _emitPaymentReceiptUseCase(
      EmitPaymentReceiptParams(paymentId: event.paymentId),
    );

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
