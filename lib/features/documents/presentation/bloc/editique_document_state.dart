part of 'editique_document_bloc.dart';

enum EditiqueDocumentStatus { initial, loading, success, failure }

class EditiqueDocumentState extends Equatable {
  final EditiqueDocumentStatus status;

  /// Type demandé — renseigné dès le déclenchement, donc disponible **aussi en
  /// échec**. C'est ce qui permet à l'écran d'erreur de savoir s'il a le droit
  /// de proposer « Réessayer » : sur une pièce non archivée, un numéro de
  /// séquence a pu être consommé, et rejouer en brûlerait un second.
  final EditiqueDocumentType? type;

  final EditiqueDocument? document;
  final EditiqueErrorType? errorType;

  const EditiqueDocumentState({
    this.status = EditiqueDocumentStatus.initial,
    this.type,
    this.document,
    this.errorType,
  });

  /// Vrai quand une reprise après échec est sûre.
  ///
  /// Une pièce **archivée** (attestation, note de perception, reçu) est
  /// idempotente : redemander re-sert les mêmes octets sous le même numéro,
  /// donc la reprise est toujours sûre — même après un délai dépassé.
  ///
  /// Une pièce **horodatée** (relevé, quitus) ne l'est jamais vraiment : le
  /// serveur consomme un numéro de séquence *avant* de rendre le PDF. Seul un
  /// échec réseau prouve que la requête n'est jamais partie ; une erreur
  /// serveur, un refus métier ou une issue inconnue laissent tous planer le
  /// doute sur un numéro déjà brûlé, et rejouer fabriquerait un doublon
  /// numéroté que le client ne verra jamais. Un type inconnu est traité comme
  /// horodaté, par prudence.
  ///
  /// Le 403 ne propose jamais de reprise, ici comme partout ailleurs.
  bool get canRetry {
    if (status != EditiqueDocumentStatus.failure) return false;
    if (errorType == EditiqueErrorType.forbidden) return false;
    if (type?.isReplayable ?? false) return true;
    return errorType == EditiqueErrorType.network;
  }

  EditiqueDocumentState copyWith({
    EditiqueDocumentStatus? status,
    EditiqueDocumentType? type,
    EditiqueDocument? document,
    EditiqueErrorType? errorType,
    bool clearDocument = false,
    bool clearError = false,
  }) {
    return EditiqueDocumentState(
      status: status ?? this.status,
      type: type ?? this.type,
      document: clearDocument ? null : (document ?? this.document),
      errorType: clearError ? null : (errorType ?? this.errorType),
    );
  }

  @override
  List<Object?> get props => [status, type, document, errorType];
}
