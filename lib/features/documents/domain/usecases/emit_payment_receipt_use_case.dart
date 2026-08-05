import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/editique_repository.dart';

/// Émet le reçu (RC) d'un paiement. Pièce archivée et idempotente.
class EmitPaymentReceiptUseCase {
  final EditiqueRepository _repository;

  const EmitPaymentReceiptUseCase(this._repository);

  Future<Either<Failure, EditiqueDocument>> call(
    EmitPaymentReceiptParams params,
  ) => _repository.emitPaymentReceipt(
    paymentId: params.paymentId,
    studentId: params.studentId,
    academicYearId: params.academicYearId,
  );
}

class EmitPaymentReceiptParams extends Equatable {
  /// Identifiant **serveur** du paiement. Les paiements encaissés hors ligne
  /// portent un uuid client jusqu'à leur synchro (`Payment.isPendingSync`) :
  /// demander leur reçu avant l'ACK produit un 404.
  final String paymentId;

  /// Attribuent la copie locale ; le serveur, lui, ne connaît que le versement.
  final String? studentId;
  final String? academicYearId;

  const EmitPaymentReceiptParams({
    required this.paymentId,
    this.studentId,
    this.academicYearId,
  });

  @override
  List<Object?> get props => [paymentId, studentId, academicYearId];
}
