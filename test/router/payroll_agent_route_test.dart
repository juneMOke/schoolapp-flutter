import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/router/hr_agent_routes.dart';

/// La fiche de paie d'un agent s'ouvre par-dessus le livre, le tableau de
/// bord et le registre des arriérés ; ailleurs, l'adresse retombe sur
/// l'écran.
void main() {
  test('les écrans de la Paie gardent la fiche par-dessus eux', () {
    for (final id in [
      MenuConstants.hrPayrollId,
      MenuConstants.hrPayrollDashboardId,
      MenuConstants.hrPayrollArrearsId,
    ]) {
      expect(HrAgentRoutes.redirectFor(id), isNull, reason: id);
    }
  });

  test('le barème n a pas de fiche : l adresse retombe sur l écran', () {
    expect(
      HrAgentRoutes.redirectFor(MenuConstants.hrPayrollSettingsId),
      isNotNull,
    );
  });
}
