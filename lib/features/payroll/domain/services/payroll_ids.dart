import 'package:uuid/uuid.dart';

/// L'identifiant d'une paie : **le même sur toutes les tablettes** et au
/// serveur — RFC 4122 v5, espace de noms = l'uuid de l'école, nom =
/// `"payroll:" + YYYY-MM`. Deux postes qui ouvrent le même mois convergent.
abstract final class PayrollIds {
  static const Uuid _uuid = Uuid();

  static String payrollId({required String schoolId, required String month}) =>
      _uuid.v5(_namespaceOf(schoolId), 'payroll:$month');

  /// Un identifiant d'école qui n'est pas un uuid (données de démonstration)
  /// reçoit un espace de noms dérivé, stable, plutôt que de faire tomber
  /// l'écran.
  static String _namespaceOf(String schoolId) =>
      Uuid.isValidUUID(fromString: schoolId)
      ? schoolId
      : _uuid.v5(Namespace.url.value, 'eteelo:school:$schoolId');
}
