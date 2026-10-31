import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Une rubrique de retenue propre à l'école (« Frais des cartes »). Aucun
/// montant au catalogue : elle vaut 0 pour chaque agent tant que l'économe n'a
/// rien saisi. [sortOrder] fixe l'ordre de calcul et d'impression.
class PayrollDeductionType extends Equatable {
  final String id;
  final String label;
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
    this.archived = false,
    this.serverKnown = false,
    this.syncState = RecordSyncState.synced,
    this.syncError,
    this.syncErrorCode,
  });

  static const int maxLabelLength = 40;

  /// Le plafond de rubriques non archivées d'une école.
  static const int maxActive = 6;

  @override
  List<Object?> get props => [
    id,
    label,
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
  final RecordSyncState syncState;
  final String? syncError;
  final String? syncErrorCode;

  const PayrollDeductionEntry({
    required this.staffMemberId,
    required this.deductionTypeId,
    required this.amountInCents,
    required this.currency,
    this.syncState = RecordSyncState.synced,
    this.syncError,
    this.syncErrorCode,
  });

  @override
  List<Object?> get props => [
    staffMemberId,
    deductionTypeId,
    amountInCents,
    currency,
    syncState,
    syncError,
    syncErrorCode,
  ];
}
