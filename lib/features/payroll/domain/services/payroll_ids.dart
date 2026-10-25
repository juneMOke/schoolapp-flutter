import 'package:uuid/uuid.dart';

/// L'identifiant d'une paie : **le même sur toutes les tablettes** et au
/// serveur — RFC 4122 v5, espace de noms = l'uuid de l'école, nom =
/// `"payroll:" + YYYY-MM`. Deux postes qui ouvrent le même mois convergent.
abstract final class PayrollIds {
  static const Uuid _uuid = Uuid();

  static String payrollId({required String schoolId, required String month}) =>
      _uuid.v5(_namespaceOf(schoolId), 'payroll:$month');

  /// Le drapeau « priorité » d'un arriéré (T9) : espace de noms = l'uuid de
  /// l'agent, nom = `"arrears-priority:" + YYYY-MM` (le mois d'origine).
  static String arrearsPriorityId({
    required String staffMemberId,
    required String month,
  }) => _uuid.v5(
    _namespaceOrDerived(staffMemberId, 'staff'),
    'arrears-priority:$month',
  );

  /// L'avance née d'une dépense payée (B5, T10) : espace de noms = l'uuid de
  /// la dépense, nom = `"salary-advance"` au premier paiement, puis
  /// `"salary-advance:" + n` quand la demande, rouverte, est payée de nouveau
  /// ([payment] = n, rang du paiement). La tablette qui paie hors ligne la
  /// projette sous l'identifiant que le serveur lui donnera.
  static String salaryAdvanceIdOf(String expenseId, {int payment = 1}) =>
      _uuid.v5(
        _namespaceOrDerived(expenseId, 'expense'),
        payment <= 1 ? 'salary-advance' : 'salary-advance:$payment',
      );

  static String _namespaceOrDerived(String id, String kind) =>
      Uuid.isValidUUID(fromString: id)
      ? id
      : _uuid.v5(Namespace.url.value, 'eteelo:$kind:$id');

  /// Un identifiant d'école qui n'est pas un uuid (données de démonstration)
  /// reçoit un espace de noms dérivé, stable, plutôt que de faire tomber
  /// l'écran.
  static String _namespaceOf(String schoolId) =>
      Uuid.isValidUUID(fromString: schoolId)
      ? schoolId
      : _uuid.v5(Namespace.url.value, 'eteelo:school:$schoolId');
}
