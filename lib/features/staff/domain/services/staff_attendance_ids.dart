import 'package:uuid/uuid.dart';

/// L'identifiant d'un pointage : **le même sur toutes les tablettes** pour un
/// agent et un jour donnés, recalculé à l'identique par le serveur.
///
/// RFC 4122 v5 : espace de noms = l'uuid de l'agent, nom =
/// `"attendance:" + YYYY-MM-DD` en UTF-8. Deux pointeurs qui pointent le même
/// agent le même jour écrivent donc la même ligne, arbitrée au dernier écrit.
abstract final class StaffAttendanceIds {
  static const Uuid _uuid = Uuid();

  static String recordId({
    required String staffMemberId,
    required String workDate,
  }) => _uuid.v5(_namespaceOf(staffMemberId), 'attendance:$workDate');

  /// L'uuid de l'agent. Un identifiant qui n'en est pas un (reprise ancienne,
  /// données de démonstration) ne doit pas faire tomber l'écran : il reçoit
  /// un espace de noms dérivé, stable — le serveur, qui ne connaît que des
  /// uuid, n'en verra jamais.
  static String _namespaceOf(String staffMemberId) =>
      Uuid.isValidUUID(fromString: staffMemberId)
      ? staffMemberId
      : _uuid.v5(Namespace.url.value, 'eteelo:staff:$staffMemberId');
}
