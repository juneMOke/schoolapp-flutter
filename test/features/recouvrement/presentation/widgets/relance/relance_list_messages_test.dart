import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/error/report_line_cap.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/relance_list_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/relance/relance_list_delivery.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce qu'on DIT au lecteur quand l'édition échoue.
///
/// ⚠️ L'intercepteur global rend des `Failure` **nues** sur 401, 403 et 404 —
/// sans le mixin `ApiErrorDetails`. Les chercher par `code` ne les trouvait
/// jamais, et les deux tombaient sur le message générique : un serveur qui
/// n'a pas encore la route faisait chercher un bug dans l'app.
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  String messageOf(Failure failure, {Duration? retryAfter}) =>
      RelanceListDelivery.message(
        failure,
        RelanceListState(retryAfter: retryAfter),
        l10n,
      );

  test('404 : la route n\'est pas déployée, et on le DIT', () {
    expect(
      messageOf(const NotFoundFailure('Resource not found')),
      l10n.recouvrementRelanceListNotDeployed,
      reason: 'sans ce cas, un serveur en retard passait pour un bug de l\'app',
    );
  });

  test('403 : le droit manque, et jamais un « Réessayer »', () {
    expect(
      messageOf(const UnauthorizedFailure('Access forbidden')),
      l10n.recouvrementRelanceListForbidden,
    );
  });

  test('429 : on ATTEND, et le délai est celui du serveur', () {
    expect(
      messageOf(
        const TooManyRequestsFailure(retryAfter: Duration(seconds: 30)),
        retryAfter: const Duration(seconds: 30),
      ),
      l10n.recouvrementRelanceListBusy(30),
    );
  });

  test('le plafond : nos mots, ses chiffres', () {
    expect(
      messageOf(
        const ApiValidationFailure(
          code: ApiErrorCode.businessRule,
          detailCode: ReportLineCap.detailCode,
          details: {'lines': 7412, 'cap': 5000},
        ),
      ),
      l10n.recouvrementRelanceListTooLarge(7412, 5000),
    );
  });

  test('une ligne incohérente est NOTRE bug : message générique', () {
    expect(
      messageOf(
        const ApiValidationFailure(
          code: ApiErrorCode.businessRule,
          detailCode: 'INCONSISTENT_LINE',
          details: {'studentId': 'abc'},
        ),
      ),
      l10n.recouvrementRelanceListInconsistent,
      reason: 'l\'index de la ligne fautive n\'apprendrait rien au lecteur',
    );
  });

  test('un échec sans rien de reconnaissable retombe sur le générique', () {
    expect(
      messageOf(const ServerFailure('boum')),
      l10n.recouvrementRelanceListFailed,
    );
  });
}
