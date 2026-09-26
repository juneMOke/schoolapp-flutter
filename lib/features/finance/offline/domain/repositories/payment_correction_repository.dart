import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_origin.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_reason.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Un geste « Annuler » ou « Corriger » sur un versement, tel que le guichet
/// le saisit.
class PaymentCorrectionDraft {
  /// Le versement visé (l'origine).
  final String paymentId;

  final PaymentCorrectionReason reason;

  /// Précision libre, obligatoire pour [PaymentCorrectionReason.other].
  final String? reasonDetail;

  /// Le caissier confirme que de l'argent a vraiment changé de main (D8).
  final bool cashMoved;

  /// Le versement de remplacement, `null` pour une annulation seule. Il peut
  /// viser un autre élève de l'école (D1) ; sa date vaut par défaut celle de
  /// l'origine (D2).
  final RecordPaymentDraft? replacement;

  const PaymentCorrectionDraft({
    required this.paymentId,
    required this.reason,
    this.reasonDetail,
    this.cashMoved = false,
    this.replacement,
  });

  PaymentCorrectionGesture get gesture => replacement == null
      ? PaymentCorrectionGesture.cancel
      : PaymentCorrectionGesture.replace;
}

/// Ce que le geste a écrit sur la tablette.
class PaymentCorrectionOutcome {
  final String correctionId;

  /// Le remplaçant, `null` pour une annulation seule.
  final String? replacementPaymentId;

  /// L'origine n'avait jamais été acceptée par le serveur : la correction
  /// vaut sur la tablette seule et rien ne partira en son nom (R2).
  final bool localOnly;

  const PaymentCorrectionOutcome({
    required this.correctionId,
    this.replacementPaymentId,
    this.localOnly = false,
  });
}

abstract interface class PaymentCorrectionRepository {
  /// Applique le geste en UNE transaction locale : correction inscrite,
  /// remplaçant écrit avec son reçu `PROV-…`, entrée d'outbox. L'origine sort
  /// des soldes tout de suite ; `payments.cancelled_at` n'est pas touché.
  ///
  /// `ValidationFailure` : motif sans rapport avec le geste, précision
  /// manquante, versement introuvable ou déjà annulé, remplaçant invalide.
  Future<Either<Failure, PaymentCorrectionOutcome>> correctPayment(
    PaymentCorrectionDraft draft,
  );

  /// Le versement à corriger, pour pré-remplir le remplaçant.
  /// `NotFoundFailure` s'il n'existe pas en local.
  Future<Either<Failure, PaymentCorrectionOrigin>> loadOrigin(String paymentId);
}
