import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Erreur d'une zone du tableau de bord du personnel (règle n°10) — **en
/// ligne** : une panne est celle du serveur, jamais « de cette tablette »
/// comme pour le Fichier. Le 403 ne propose jamais « Réessayer » ; le 401
/// propose de se reconnecter.
class HrDashboardResultsErrorState extends StatelessWidget {
  final Failure? failure;
  final VoidCallback? onRetry;

  const HrDashboardResultsErrorState({super.key, this.failure, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = EteeloErrorType.fromFailure(failure);
    final incident = failure is ApiErrorDetails
        ? (failure! as ApiErrorDetails).incidentId
        : null;
    return EteeloErrorResult(
      type: type,
      title: switch (type) {
        EteeloErrorType.network => l10n.staffErrorNetworkTitle,
        EteeloErrorType.unauthorized => l10n.staffErrorUnauthorizedTitle,
        EteeloErrorType.forbidden => l10n.staffErrorForbiddenTitle,
        _ => l10n.hrDashboardErrorServerTitle,
      },
      message: switch (type) {
        EteeloErrorType.network => l10n.staffErrorNetwork,
        EteeloErrorType.unauthorized => l10n.staffErrorUnauthorized,
        EteeloErrorType.forbidden => l10n.staffErrorForbidden,
        _ => l10n.hrDashboardErrorServer,
      },
      primaryAction: switch (type) {
        EteeloErrorType.forbidden => null,
        EteeloErrorType.unauthorized => EteeloButton.primary(
          label: l10n.staffErrorReconnect,
          icon: Icons.login,
          onPressed: () =>
              context.read<AuthBloc>().add(const AuthLogoutRequested()),
          fullWidth: false,
        ),
        _ =>
          onRetry == null
              ? null
              : EteeloButton.primary(
                  label: l10n.staffErrorRetry,
                  icon: Icons.refresh,
                  onPressed: onRetry,
                  fullWidth: false,
                ),
      },
      incidentCodeLabel:
          type == EteeloErrorType.server &&
              incident != null &&
              incident.trim().isNotEmpty
          ? l10n.staffErrorIncidentCode(incident)
          : null,
    );
  }
}
