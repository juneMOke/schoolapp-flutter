import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_trace_use_cases.dart';

/// Quand le dernier ticket est-il sorti pour ce versement ? Rien de plus.
///
/// ## Ce qu'il a cessé d'être
///
/// Une **grille d'affichage**. Il répondait « ce versement attend-il son
/// premier papier ? », et la ligne d'impression n'apparaissait que sur un
/// « oui ». La réimpression étant désormais libre — patron de la boutique —, le
/// bouton est toujours offert et ce cubit n'alimente plus que ce que la ligne
/// **dit** : quel libellé sur le bouton, quelle phrase en dessous.
///
/// L'état initial est délibérément « rien d'imprimé ». La ligne ne doit jamais
/// changer de mot sous les doigts du caissier entre l'ouverture de la modale et
/// la réponse de la base ; commencer par la formulation d'un premier tirage est
/// le moins mauvais des deux sens, puisqu'un caissier qui lirait « Réimprimer »
/// puis « Imprimer maintenant » se demanderait ce qu'il a manqué.
class TicketPrintStatusCubit extends Cubit<TicketPrintStatusState> {
  final TicketPrintedAtUseCase _ticketPrintedAt;

  TicketPrintStatusCubit(this._ticketPrintedAt)
    : super(const TicketPrintStatusState());

  Future<void> load(String paymentId) async {
    if (paymentId.trim().isEmpty) return;

    final printedAt = await _ticketPrintedAt(paymentId);
    if (isClosed) return;

    emit(TicketPrintStatusState(loaded: true, printedAt: printedAt));
  }
}

class TicketPrintStatusState extends Equatable {
  final bool loaded;

  /// Horodatage de la **dernière** impression sur cette tablette, `null` si
  /// aucun papier n'est connu — y compris quand la lecture a échoué.
  ///
  /// La dernière et non la première : la trace est réécrite à chaque tirage
  /// thermique réussi, pour qu'un caissier puisse s'y fier.
  final DateTime? printedAt;

  const TicketPrintStatusState({this.loaded = false, this.printedAt});

  /// Vrai dès qu'un papier est sorti d'ici. C'est ce qui fait basculer le
  /// libellé de « Imprimer maintenant » à « Réimprimer le ticket ».
  bool get wasPrinted => printedAt != null;

  @override
  List<Object?> get props => [loaded, printedAt];
}
