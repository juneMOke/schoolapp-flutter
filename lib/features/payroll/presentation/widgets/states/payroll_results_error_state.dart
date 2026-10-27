import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/states/hr_dashboard_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Erreur du tableau de bord de la paie (règle n° 10), **en ligne** : les
/// quatre anatomies de l'écran RH en ligne, avec les mots de la paie. Le 403
/// ne propose jamais « Réessayer ».
class PayrollResultsErrorState extends StatelessWidget {
  final Failure? failure;
  final VoidCallback? onRetry;

  const PayrollResultsErrorState({super.key, this.failure, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HrDashboardResultsErrorState(
      failure: failure,
      onRetry: onRetry,
      serverTitle: l10n.payrollDashErrorServerTitle,
      serverMessage: l10n.payrollDashErrorServer,
      forbiddenMessage: l10n.payrollDashErrorForbidden,
    );
  }
}
