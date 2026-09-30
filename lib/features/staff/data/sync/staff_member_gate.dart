import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Où en est, sur la tablette, la fiche d'un agent dont dépend un envoi.
enum StaffParentState {
  /// Inconnue du poste : le serveur jugera.
  missing,

  /// Jamais accusée, pas encore refusée : l'envoi attend.
  unsent,

  /// Jamais accusée **et** refusée : elle n'arrivera jamais au serveur.
  refused,

  /// Accusée au moins une fois.
  acknowledged,
}

/// La sortie de secours des envois qui dépendent d'une fiche d'agent
/// (pointage, profil de paie, éléments variables, avances, versements) : le
/// serveur répond `409 STAFF_MEMBER_NOT_YET_SYNCED` tant que la fiche ne lui
/// est pas arrivée ; si elle a été refusée, elle n'arrivera jamais, et l'envoi
/// doit échouer à son tour au lieu d'attendre sans fin.
class StaffMemberGate {
  final StaffMemberDao _members;

  const StaffMemberGate(this._members);

  /// Le code rangé sur un envoi dont la fiche parente a été refusée.
  static const String parentRefusedCode = 'STAFF_MEMBER_REFUSED';

  Future<({StaffParentState state, String? name})> of(String memberId) async {
    final member = await _members.find(memberId);
    if (member == null) return (state: StaffParentState.missing, name: null);
    final name = member.toEntity().fullName;
    if (member.row['version'] != null) {
      return (state: StaffParentState.acknowledged, name: name);
    }
    final refused = member.syncStatus == StaffSyncState.failed.dbValue;
    return (
      state: refused ? StaffParentState.refused : StaffParentState.unsent,
      name: name,
    );
  }
}
