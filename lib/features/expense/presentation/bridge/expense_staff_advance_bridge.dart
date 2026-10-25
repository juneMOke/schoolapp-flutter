import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_staff_advance.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';

/// Le pont vers la Paie (spec « PaieDepBridge ») : une avance ou un prêt au
/// personnel déposé depuis Dépenses ▸ Nouvelle demande. Le bloc R.H. — agent,
/// nature, échéances, motif — se saisit dans le formulaire de la Paie, qui
/// seul connaît les contrats ; la demande rejoint ensuite le registre comme
/// toute dépense.
///
/// Implémenté et posé par la Paie ; absent (Paie non montée), le type reste
/// hors du formulaire.
abstract class ExpenseStaffAdvanceBridge {
  /// Le compte peut-il déposer une avance ? Le serveur exige `hr.pay.read`
  /// en plus du droit d'écrire une dépense (`STAFF_ADVANCE_FORBIDDEN`).
  bool allows(List<String>? permissions);

  /// Ouvre la saisie de la Paie et dépose la demande ; annonce lui-même son
  /// issue.
  Future<void> request(BuildContext context);

  /// Le pont, si la Paie est montée et que la session peut déposer une
  /// avance ; sinon `null`, et le type reste hors du formulaire.
  static ExpenseStaffAdvanceBridge? offeredIn(BuildContext context) {
    if (!GetIt.instance.isRegistered<ExpenseStaffAdvanceBridge>()) return null;
    final bridge = GetIt.instance<ExpenseStaffAdvanceBridge>();
    final permissions = PermissionGate.maybeBlocOf(context)?.state.permissions;
    return bridge.allows(permissions) ? bridge : null;
  }

  /// Le type semé par le serveur (T12), s'il est actif.
  static ExpenseType? typeOf(List<ExpenseType> types) {
    for (final type in types) {
      if (type.code == ExpenseStaffAdvance.typeCode) return type;
    }
    return null;
  }
}
