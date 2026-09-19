import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_detail.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/claim_sale_receipt_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sale_detail_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/mark_sale_ticket_printed_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';

enum SaleDetailStatus { initial, loading, ready, failure }

class SaleDetailState extends Equatable {
  final SaleDetailStatus status;
  final SaleDetail? detail;
  final Failure? failure;

  const SaleDetailState({
    this.status = SaleDetailStatus.initial,
    this.detail,
    this.failure,
  });

  @override
  List<Object?> get props => [status, detail, failure];
}

/// La fiche d'une vente déjà encaissée — **lecture locale**, comme la liste.
///
/// Un cubit et non un bloc : deux gestes, aucun enchaînement à arbitrer.
class SaleDetailCubit extends Cubit<SaleDetailState> {
  final GetBoutiqueSaleDetailUseCase _getDetail;
  final MarkSaleTicketPrintedUseCase _markPrinted;
  final ClaimSaleReceiptUseCase _claimReceipt;
  final String saleId;

  SaleDetailCubit({
    required GetBoutiqueSaleDetailUseCase getDetail,
    required MarkSaleTicketPrintedUseCase markPrinted,
    required ClaimSaleReceiptUseCase claimReceipt,
    required this.saleId,
  }) : _getDetail = getDetail,
       _markPrinted = markPrinted,
       _claimReceipt = claimReceipt,
       super(const SaleDetailState());

  Future<void> load() async {
    emit(const SaleDetailState(status: SaleDetailStatus.loading));
    final result = await _getDetail(saleId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        SaleDetailState(status: SaleDetailStatus.failure, failure: failure),
      ),
      (detail) =>
          emit(SaleDetailState(status: SaleDetailStatus.ready, detail: detail)),
    );
  }

  /// Note l'impression et relit la fiche pour en afficher la trace.
  ///
  /// ⚠️ **Appelé APRÈS une impression réussie seulement.** Marquer un envoi
  /// qui a échoué ferait afficher « déjà imprimé » sur un ticket que personne
  /// n'a en main.
  Future<void> ticketPrinted() async {
    await _markPrinted(saleId);
    if (isClosed) return;
    await load();
  }

  /// Réclame au serveur le reçu scellé, puis **relit la fiche**.
  ///
  /// Rend la pièce à l'appelant plutôt que de la ranger dans l'état : les octets
  /// sont déjà en main, et l'écran les affiche immédiatement — passer par la
  /// restitution referait un second téléchargement de la pièce qui vient
  /// d'arriver, le `RV` étant exclu du cache local.
  ///
  /// La relecture n'est pas décorative : c'est elle qui fait disparaître la
  /// référence `PROV-` de la ligne « Reçu », du titre et de tout ticket
  /// réimprimé ensuite.
  ///
  /// ⚠️ Elle a lieu **même en cas d'échec de la réclamation** : la pièce a pu
  /// être consignée pendant que la réponse se perdait, et garder l'écran sur un
  /// état périmé y afficherait un `PROV-` que la base ne porte plus.
  Future<Either<Failure, EditiqueDocument>> claimReceipt() async {
    final outcome = await _claimReceipt(saleId);
    if (isClosed) return outcome;
    await load();
    return outcome;
  }
}
