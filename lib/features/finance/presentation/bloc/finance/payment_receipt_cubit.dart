import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_payment_receipt_document_use_case.dart';

/// Numéro de pièce du reçu d'un paiement, pour la ligne « Reçu n° » du détail.
///
/// Volontairement minuscule et sans état d'erreur : c'est une information
/// d'affichage. Quand elle manque, la ligne reste neutre — le reste du détail
/// (montant, payeur, imputations) n'a pas à en souffrir.
class PaymentReceiptCubit extends Cubit<PaymentReceiptState> {
  final GetPaymentReceiptDocumentUseCase _getPaymentReceiptDocumentUseCase;

  PaymentReceiptCubit(this._getPaymentReceiptDocumentUseCase)
    : super(const PaymentReceiptState());

  Future<void> load(String paymentId) async {
    final document = await _getPaymentReceiptDocumentUseCase(paymentId);
    if (isClosed) return;
    emit(
      PaymentReceiptState(
        loaded: true,
        number: document?.number,
        // `PROV-…` tant que l'encaissement n'a pas été acquitté par le serveur.
        // Ce n'est pas un numéro de pièce officiel : l'UI doit le dire plutôt
        // que de l'afficher comme un numéro définitif.
        isProvisional: document?.isProvisional ?? false,
      ),
    );
  }
}

class PaymentReceiptState extends Equatable {
  final bool loaded;
  final String? number;
  final bool isProvisional;

  const PaymentReceiptState({
    this.loaded = false,
    this.number,
    this.isProvisional = false,
  });

  /// Vrai quand un numéro **définitif** est connu et affichable tel quel.
  bool get hasDefinitiveNumber =>
      !isProvisional && (number?.trim().isNotEmpty ?? false);

  @override
  List<Object?> get props => [loaded, number, isProvisional];
}
