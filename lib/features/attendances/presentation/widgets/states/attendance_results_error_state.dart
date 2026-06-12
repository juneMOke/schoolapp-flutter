import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Etat d'erreur de l'appel (presences) : reutilise l'anatomie partagee
/// [EteeloErrorResult] (medaillon + titre + message + action) pilotee par le
/// type d'erreur. Les 4 familles couvertes par la charte sont :
/// reseau, 401 (session expiree), 403 (acces refuse), 500 (serveur).
///
/// Mapping backend (cf. interceptor Dio) : HTTP 401 -> `InvalidCredentialsFailure`
/// -> 401 (session expiree), HTTP 403 -> `UnauthorizedFailure` -> 403 (acces refuse).
class AttendanceResultsErrorState extends StatelessWidget {
  final AttendanceErrorType type;
  final String? incidentCode;
  final VoidCallback? onRetry;
  final VoidCallback? onReconnect;
  final VoidCallback? onContactAdmin;

  const AttendanceResultsErrorState({
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
    final incidentCodeLabel =
        viewType == EteeloErrorType.server &&
            incidentCode != null &&
            incidentCode!.trim().isNotEmpty
        ? l10n.attendanceErrorIncidentCode(incidentCode!)
        : null;

    return EteeloErrorResult(
      type: viewType,
      title: _title(l10n, viewType),
      message: _message(l10n, viewType),
      primaryAction: action == null
          ? null
          : FilledButton.icon(
              onPressed: action.onPressed,
              icon: Icon(action.icon, size: 16),
              label: Text(action.label),
            ),
      incidentCodeLabel: incidentCodeLabel,
      autofocusPrimaryAction: action != null,
      fullWidthCard: true,
    );
  }

  /// Reduit les variantes backend d'`AttendanceErrorType` aux 5 familles
  /// d'affichage de la charte.
  EteeloErrorType get _viewType => switch (type) {
    AttendanceErrorType.network => EteeloErrorType.network,
    AttendanceErrorType.unauthorized ||
    AttendanceErrorType.invalidCredentials ||
    AttendanceErrorType.auth => EteeloErrorType.unauthorized,
    AttendanceErrorType.forbidden => EteeloErrorType.forbidden,
    AttendanceErrorType.server ||
    AttendanceErrorType.storage => EteeloErrorType.server,
    AttendanceErrorType.notFound ||
    AttendanceErrorType.validation ||
    AttendanceErrorType.none ||
    AttendanceErrorType.unknown => EteeloErrorType.unknown,
  };

  _ErrorAction? _primaryAction(
    AppLocalizations l10n,
    EteeloErrorType viewType,
  ) {
    return switch (viewType) {
      // 403 ne propose jamais « Reessayer » : seule l'action de contact est
      // pertinente puisque l'acces est refuse par les droits.
      EteeloErrorType.forbidden =>
        onContactAdmin == null
            ? null
            : _ErrorAction(
                label: l10n.attendanceErrorContactAdmin,
                icon: Icons.mail_outline_rounded,
                onPressed: onContactAdmin!,
              ),
      EteeloErrorType.unauthorized =>
        onReconnect == null
            ? null
            : _ErrorAction(
                label: l10n.attendanceErrorReconnect,
                icon: Icons.lock_open_rounded,
                onPressed: onReconnect!,
              ),
      EteeloErrorType.network ||
      EteeloErrorType.server ||
      EteeloErrorType.unknown =>
        onRetry == null
            ? null
            : _ErrorAction(
                label: l10n.attendanceErrorRetry,
                icon: Icons.refresh_rounded,
                onPressed: onRetry!,
              ),
    };
  }

  String _title(AppLocalizations l10n, EteeloErrorType viewType) {
    return switch (viewType) {
      EteeloErrorType.network => l10n.attendanceErrorNetworkTitle,
      EteeloErrorType.unauthorized => l10n.attendanceErrorUnauthorizedTitle,
      EteeloErrorType.forbidden => l10n.attendanceErrorForbiddenTitle,
      EteeloErrorType.server => l10n.attendanceErrorServerTitle,
      EteeloErrorType.unknown => l10n.attendanceErrorUnknownTitle,
    };
  }

  String _message(AppLocalizations l10n, EteeloErrorType viewType) {
    return switch (viewType) {
      EteeloErrorType.network => l10n.attendanceErrorNetworkMessage,
      EteeloErrorType.unauthorized => l10n.attendanceErrorUnauthorizedMessage,
      EteeloErrorType.forbidden => l10n.attendanceErrorForbiddenMessage,
      EteeloErrorType.server => l10n.attendanceErrorServerMessage,
      EteeloErrorType.unknown => l10n.attendanceErrorUnknownMessage,
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
