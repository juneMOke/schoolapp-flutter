import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/states/hr_dashboard_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Erreur d'un écran en ligne de RH · Présences (règle n°10) : l'anatomie du
/// tableau de bord du personnel, avec nos mots pour une panne du serveur.
/// Hors ligne, c'est l'erreur réseau — seul le registre lit la tablette (D1).
class HrPresenceResultsErrorState extends StatelessWidget {
  final Failure? failure;
  final VoidCallback? onRetry;

  const HrPresenceResultsErrorState({super.key, this.failure, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HrDashboardResultsErrorState(
      failure: failure,
      onRetry: onRetry,
      serverTitle: l10n.hrPresenceErrorServerTitle,
      serverMessage: l10n.hrPresenceErrorServer,
      forbiddenMessage: l10n.hrPresenceErrorForbidden,
    );
  }
}
