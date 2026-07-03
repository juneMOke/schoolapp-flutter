import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/schedule_error_type.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// État d'erreur de l'emploi du temps : réutilise l'anatomie partagée
/// [EteeloErrorResult] (médaillon + titre + message + action) pilotée par le
/// type d'erreur. Les 4 familles de la charte : réseau, 401 (session expirée),
/// 403 (accès refusé), 500 (serveur).
///
/// Mapping backend (cf. interceptor Dio) : HTTP 401 → `InvalidCredentialsFailure`
/// → 401 ; HTTP 403 → `UnauthorizedFailure` → 403. Le 403 ne propose **jamais**
/// « Réessayer » (l'accès est refusé par les droits).
class ScheduleResultsErrorState extends StatelessWidget {
  final ScheduleErrorType type;
  final String? incidentCode;
  final VoidCallback? onRetry;
  final VoidCallback? onReconnect;
  final VoidCallback? onContactAdmin;

  const ScheduleResultsErrorState({
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
        ? l10n.scheduleErrorIncidentCode(code)
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

  /// Réduit les variantes backend de [ScheduleErrorType] aux 5 familles
  /// d'affichage de la charte.
  EteeloErrorType get _viewType => switch (type) {
    ScheduleErrorType.network => EteeloErrorType.network,
    ScheduleErrorType.invalidCredentials ||
    ScheduleErrorType.auth => EteeloErrorType.unauthorized,
    ScheduleErrorType.forbidden => EteeloErrorType.forbidden,
    ScheduleErrorType.server ||
    ScheduleErrorType.storage => EteeloErrorType.server,
    ScheduleErrorType.none ||
    ScheduleErrorType.notFound ||
    ScheduleErrorType.validation ||
    ScheduleErrorType.conflict ||
    ScheduleErrorType.unknown => EteeloErrorType.unknown,
  };

  _ErrorAction? _primaryAction(
    AppLocalizations l10n,
    EteeloErrorType viewType,
  ) {
    return switch (viewType) {
      // 403 ne propose jamais « Réessayer » : seule l'action de contact est
      // pertinente puisque l'accès est refusé par les droits.
      EteeloErrorType.forbidden =>
        onContactAdmin == null
            ? null
            : _ErrorAction(
                label: l10n.scheduleErrorContactAdmin,
                icon: Icons.mail_outline_rounded,
                onPressed: onContactAdmin!,
              ),
      EteeloErrorType.unauthorized =>
        onReconnect == null
            ? null
            : _ErrorAction(
                label: l10n.scheduleErrorReconnect,
                icon: Icons.lock_open_rounded,
                onPressed: onReconnect!,
              ),
      EteeloErrorType.network ||
      EteeloErrorType.server ||
      EteeloErrorType.unknown =>
        onRetry == null
            ? null
            : _ErrorAction(
                label: l10n.scheduleErrorRetry,
                icon: Icons.refresh_rounded,
                onPressed: onRetry!,
              ),
    };
  }

  String _title(AppLocalizations l10n, EteeloErrorType viewType) {
    return switch (viewType) {
      EteeloErrorType.network => l10n.scheduleErrorNetworkTitle,
      EteeloErrorType.unauthorized => l10n.scheduleErrorUnauthorizedTitle,
      EteeloErrorType.forbidden => l10n.scheduleErrorForbiddenTitle,
      EteeloErrorType.server => l10n.scheduleErrorServerTitle,
      EteeloErrorType.unknown => l10n.scheduleErrorUnknownTitle,
    };
  }

  String _message(AppLocalizations l10n, EteeloErrorType viewType) {
    return switch (viewType) {
      EteeloErrorType.network => l10n.scheduleErrorNetworkMessage,
      EteeloErrorType.unauthorized => l10n.scheduleErrorUnauthorizedMessage,
      EteeloErrorType.forbidden => l10n.scheduleErrorForbiddenMessage,
      EteeloErrorType.server => l10n.scheduleErrorServerMessage,
      EteeloErrorType.unknown => l10n.scheduleErrorUnknownMessage,
    };
  }
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
