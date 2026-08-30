import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_detail.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sale_detail_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/mark_sale_ticket_printed_use_case.dart';

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
  final String saleId;

  SaleDetailCubit({
    required GetBoutiqueSaleDetailUseCase getDetail,
    required MarkSaleTicketPrintedUseCase markPrinted,
    required this.saleId,
  }) : _getDetail = getDetail,
       _markPrinted = markPrinted,
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
}
