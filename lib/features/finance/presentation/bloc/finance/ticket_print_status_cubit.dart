import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_trace_use_cases.dart';

/// Ce versement attend-il son premier ticket ? Rien de plus.
///
/// Minuscule et sans état d'erreur, à l'image de `PaymentReceiptCubit` : une
/// lecture illisible se lit « non », donc l'action ne s'affiche pas. Refuser un
/// rattrapage n'a jamais fait perdre d'argent ; le proposer à tort ferait
/// ressortir un papier déjà remis, ce que l'ADR-013 interdit.
///
/// L'état initial est délibérément « pas d'attente » : la ligne ne doit jamais
/// **apparaître puis disparaître** sous les doigts du caissier, qui aurait pu
/// appuyer entre-temps.
class TicketPrintStatusCubit extends Cubit<TicketPrintStatusState> {
  final AwaitsTicketPrintUseCase _awaitsTicketPrint;

  TicketPrintStatusCubit(this._awaitsTicketPrint)
    : super(const TicketPrintStatusState());

  Future<void> load(String paymentId) async {
    if (paymentId.trim().isEmpty) return;

    final awaits = await _awaitsTicketPrint(paymentId);
    if (isClosed) return;

    emit(TicketPrintStatusState(loaded: true, awaitsPrint: awaits));
  }
}

class TicketPrintStatusState extends Equatable {
  final bool loaded;

  /// Vrai seulement quand la réponse est connue ET positive.
  final bool awaitsPrint;

  const TicketPrintStatusState({this.loaded = false, this.awaitsPrint = false});

  @override
  List<Object?> get props => [loaded, awaitsPrint];
}
