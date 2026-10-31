import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Ce que le formulaire d'une rubrique décide : la fiche, sans son rang ni son
/// état.
class PayrollDeductionTypeDraft extends Equatable {
  final String code;
  final String label;
  final String? description;
  final String currency;
  final int defaultAmountInCents;

  const PayrollDeductionTypeDraft({
    required this.code,
    required this.label,
    required this.description,
    required this.currency,
    required this.defaultAmountInCents,
  });

  @override
  List<Object?> get props => [
    code,
    label,
    description,
    currency,
    defaultAmountInCents,
  ];
}

/// Une rubrique de retenue propre à l'école (« Frais des cartes »).
/// [defaultAmountInCents] s'applique chaque mois aux agents payés en
/// [currency], sans saisie ; la saisie d'un agent le remplace, 0 compris.
/// [sortOrder] fixe l'ordre de calcul et d'impression.
class PayrollDeductionType extends Equatable {
  final String id;

  /// Unique dans l'école, archivées comprises ; figé une fois utilisée.
  final String code;
  final String label;
  final String? description;

  /// Figée une fois utilisée. Vide : la rubrique n'est encore servie que par
  /// un serveur antérieur au contrat, elle ne s'applique à personne.
  final String currency;
  final int defaultAmountInCents;
  final int sortOrder;

  /// Archivée, elle n'accepte plus de montant, mais ceux déjà saisis sur un
  /// brouillon comptent toujours : archiver ne change aucun net en silence.
  final bool archived;

  /// Le serveur l'a déjà eue : sa suppression passe par lui, en ligne.
  final bool serverKnown;
  final RecordSyncState syncState;
  final String? syncError;
  final String? syncErrorCode;

  const PayrollDeductionType({
    required this.id,
    required this.label,
    required this.sortOrder,
    this.code = '',
    this.description,
    this.currency = '',
    this.defaultAmountInCents = 0,
    this.archived = false,
    this.serverKnown = false,
    this.syncState = RecordSyncState.synced,
    this.syncError,
    this.syncErrorCode,
  });

  static const int maxLabelLength = 40;
  static const int maxCodeLength = 12;
  static const int maxDescriptionLength = 200;

  /// 2 à 12 caractères, en majuscules.
  static final RegExp codeFormat = RegExp(r'^[A-Z0-9_-]{2,12}$');

  /// Le plafond de rubriques non archivées par devise.
  static const int maxActive = 6;

  /// Refusée sans que le serveur l'ait jamais eue, elle n'existe pas chez lui :
  /// son défaut ne compte pas, sinon la tablette signerait un autre livre.
  bool get defaultCounts => syncState != RecordSyncState.failed || serverKnown;

  /// Refusée alors que le serveur la connaît : le défaut qu'il tient peut
  /// différer du nôtre jusqu'à la prochaine descente.
  bool get refusedOnServer =>
      syncState == RecordSyncState.failed && serverKnown;

  /// La rubrique concerne-t-elle une ligne de cette devise ?
  bool appliesTo(String lineCurrency) =>
      CurrencyCode.normalize(currency) == CurrencyCode.normalize(lineCurrency);

  /// La même rubrique, pour une nouvelle écriture : l'état de synchronisation
  /// ne suit pas.
  PayrollDeductionType rewritten({
    PayrollDeductionTypeDraft? draft,
    int? sortOrder,
    bool? archived,
  }) => PayrollDeductionType(
    id: id,
    code: draft?.code ?? code,
    label: draft?.label ?? label,
    description: draft == null ? description : draft.description,
    currency: draft?.currency ?? currency,
    defaultAmountInCents: draft?.defaultAmountInCents ?? defaultAmountInCents,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
    serverKnown: serverKnown,
  );

  @override
  List<Object?> get props => [
    id,
    code,
    label,
    description,
    currency,
    defaultAmountInCents,
    sortOrder,
    archived,
    serverKnown,
    syncState,
    syncError,
    syncErrorCode,
  ];
}

/// Le montant saisi pour un agent, une rubrique et un mois, en centimes de
/// [currency] — la devise de la ligne au moment de la saisie. `0` retire la
/// retenue, mais la saisie reste, avec son horloge.
class PayrollDeductionEntry extends Equatable {
  final String staffMemberId;
  final String deductionTypeId;
  final int amountInCents;
  final String currency;

  /// Ce que le serveur tient pour cette clé ; `null` : rien.
  final int? serverAmountInCents;
  final String? serverCurrency;
  final RecordSyncState syncState;
  final String? syncError;
  final String? syncErrorCode;

  const PayrollDeductionEntry({
    required this.staffMemberId,
    required this.deductionTypeId,
    required this.amountInCents,
    required this.currency,
    this.serverAmountInCents,
    this.serverCurrency,
    this.syncState = RecordSyncState.synced,
    this.syncError,
    this.syncErrorCode,
  });

  /// Ce qui compte vraiment. Un refus n'a rien écrit au serveur : la valeur
  /// qu'il tenait reste en vigueur, sinon la tablette signerait un autre livre.
  /// `null` : rien à compter.
  PayrollDeductionEntry? get counted {
    if (syncState != RecordSyncState.failed) return this;
    final amount = serverAmountInCents;
    final currency = serverCurrency;
    if (amount == null || currency == null) return null;
    return PayrollDeductionEntry(
      staffMemberId: staffMemberId,
      deductionTypeId: deductionTypeId,
      amountInCents: amount,
      currency: currency,
    );
  }

  @override
  List<Object?> get props => [
    staffMemberId,
    deductionTypeId,
    amountInCents,
    currency,
    serverAmountInCents,
    serverCurrency,
    syncState,
    syncError,
    syncErrorCode,
  ];
}
