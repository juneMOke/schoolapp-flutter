import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_error_type.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// État d'erreur du module résultats : réutilise l'anatomie partagée
/// [EteeloErrorResult] pilotée par le type d'erreur (réseau / 401 / 403 / 500).
///
/// Mapping projet (interceptor Dio) : HTTP 401 → `InvalidCredentialsFailure` →
/// `invalidCredentials` ; HTTP 403 → `UnauthorizedFailure` → `forbidden`. Le 403
/// ne propose **jamais** « Réessayer ». Ce module est 100 % lecture : aucun
/// `conflict`.
class ResultatsResultsErrorState extends StatelessWidget {
  final ResultatsErrorType type;
  final String? incidentCode;
  final VoidCallback? onRetry;
  final VoidCallback? onReconnect;
  final VoidCallback? onContactAdmin;

  const ResultatsResultsErrorState({
    super.key,
    required this.type,
    this.incidentCode,
    this.onRetry,
    this.onReconnect,
    this.onContactAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final viewType = _viewType;
    final action = _primaryAction(l10n, viewType);
    final code = incidentCode?.trim();
    final incidentCodeLabel =
        viewType == EteeloErrorType.server && code != null && code.isNotEmpty
        ? l10n.resultatsErrorIncidentCode(code)
        : null;

    return EteeloErrorResult(
      type: viewType,
      title: _title(l10n, viewType),
      message: _message(l10n, viewType),
      primaryAction: action == null
          ? null
          : EteeloButton.primary(
              label: action.label,
              icon: action.icon,
              onPressed: action.onPressed,
              fullWidth: false,
            ),
      incidentCodeLabel: incidentCodeLabel,
      autofocusPrimaryAction: action != null,
      fullWidthCard: true,
    );
  }

  /// Réduit les variantes backend de [ResultatsErrorType] aux 5 familles
  /// d'affichage de la charte.
  EteeloErrorType get _viewType => switch (type) {
    ResultatsErrorType.network => EteeloErrorType.network,
    ResultatsErrorType.invalidCredentials ||
    ResultatsErrorType.auth => EteeloErrorType.unauthorized,
    ResultatsErrorType.forbidden => EteeloErrorType.forbidden,
    ResultatsErrorType.server ||
    ResultatsErrorType.storage => EteeloErrorType.server,
    ResultatsErrorType.none ||
    ResultatsErrorType.notFound ||
    ResultatsErrorType.validation ||
    ResultatsErrorType.unknown => EteeloErrorType.unknown,
  };

  _ErrorAction? _primaryAction(
    AppLocalizations l10n,
    EteeloErrorType viewType,
  ) {
    return switch (viewType) {
      // 403 ne propose jamais « Réessayer » : l'accès est refusé par les droits.
      EteeloErrorType.forbidden =>
        onContactAdmin == null
            ? null
            : _ErrorAction(
                label: l10n.resultatsErrorContactAdmin,
                icon: Icons.mail_outline_rounded,
                onPressed: onContactAdmin!,
              ),
      EteeloErrorType.unauthorized =>
        onReconnect == null
            ? null
            : _ErrorAction(
                label: l10n.resultatsErrorReconnect,
                icon: Icons.lock_open_rounded,
                onPressed: onReconnect!,
              ),
      EteeloErrorType.network ||
      EteeloErrorType.server ||
      EteeloErrorType.unknown =>
        onRetry == null
            ? null
            : _ErrorAction(
                label: l10n.resultatsErrorRetry,
                icon: Icons.refresh_rounded,
                onPressed: onRetry!,
              ),
    };
  }

  String _title(AppLocalizations l10n, EteeloErrorType viewType) =>
      switch (viewType) {
        EteeloErrorType.network => l10n.resultatsErrorNetworkTitle,
        EteeloErrorType.unauthorized => l10n.resultatsErrorUnauthorizedTitle,
        EteeloErrorType.forbidden => l10n.resultatsErrorForbiddenTitle,
        EteeloErrorType.server => l10n.resultatsErrorServerTitle,
        EteeloErrorType.unknown => l10n.resultatsErrorUnknownTitle,
      };

  String _message(AppLocalizations l10n, EteeloErrorType viewType) =>
      switch (viewType) {
        EteeloErrorType.network => l10n.resultatsErrorNetworkMessage,
        EteeloErrorType.unauthorized => l10n.resultatsErrorUnauthorizedMessage,
        EteeloErrorType.forbidden => l10n.resultatsErrorForbiddenMessage,
        EteeloErrorType.server => l10n.resultatsErrorServerMessage,
        EteeloErrorType.unknown => l10n.resultatsErrorUnknownMessage,
      };
}

class _ErrorAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ErrorAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}
