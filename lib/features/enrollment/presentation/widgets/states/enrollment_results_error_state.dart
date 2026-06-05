import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentResultsErrorState extends StatelessWidget {
  final EnrollmentErrorType type;
  final String? message;
  final String? incidentCode;
  final VoidCallback? onRetry;
  final VoidCallback? onReconnect;
  final VoidCallback? onContactAdmin;

  const EnrollmentResultsErrorState({
    super.key,
    required this.type,
    this.message,
    this.incidentCode,
    this.onRetry,
    this.onReconnect,
    this.onContactAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final action = _primaryAction(l10n);
    final resolvedMessage = _resolveMessage(l10n);
    final incidentCodeLabel =
        type == EnrollmentErrorType.server &&
            incidentCode != null &&
            incidentCode!.trim().isNotEmpty
        ? l10n.enrollmentErrorIncidentCode(incidentCode!)
        : null;

    return EteeloErrorResult(
      type: _viewType,
      title: _title(l10n),
      message: resolvedMessage,
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

  String _resolveMessage(AppLocalizations l10n) {
    // On force un message i18n lisible pour toutes les erreurs de listing.
    // Les messages backend peuvent etre techniques et non localises.
    return _description(l10n);
  }

  _ErrorAction? _primaryAction(AppLocalizations l10n) {
    return switch (type) {
      EnrollmentErrorType.network ||
      EnrollmentErrorType.server ||
      EnrollmentErrorType.unknown =>
        onRetry == null
            ? null
            : _ErrorAction(
                label: l10n.enrollmentErrorRetry,
                icon: Icons.refresh_rounded,
                onPressed: onRetry!,
              ),
      EnrollmentErrorType.unauthorized =>
        onReconnect == null
            ? null
            : _ErrorAction(
                label: l10n.enrollmentErrorReconnect,
                icon: Icons.lock_open_rounded,
                onPressed: onReconnect!,
              ),
      EnrollmentErrorType.forbidden =>
        onContactAdmin == null
            ? null
            : _ErrorAction(
                label: l10n.enrollmentErrorContactAdmin,
                icon: Icons.mail_outline_rounded,
                onPressed: onContactAdmin!,
              ),
    };
  }

  String _title(AppLocalizations l10n) {
    return switch (type) {
      EnrollmentErrorType.network => l10n.enrollmentErrorNetworkTitle,
      EnrollmentErrorType.unauthorized => l10n.enrollmentErrorUnauthorizedTitle,
      EnrollmentErrorType.forbidden => l10n.enrollmentErrorForbiddenTitle,
      EnrollmentErrorType.server => l10n.enrollmentErrorServerTitle,
      EnrollmentErrorType.unknown => l10n.enrollmentErrorUnknownTitle,
    };
  }

  String _description(AppLocalizations l10n) {
    return switch (type) {
      EnrollmentErrorType.network => l10n.enrollmentErrorNetworkMessage,
      EnrollmentErrorType.unauthorized =>
        l10n.enrollmentErrorUnauthorizedMessage,
      EnrollmentErrorType.forbidden => l10n.enrollmentErrorForbiddenMessage,
      EnrollmentErrorType.server => l10n.enrollmentErrorServerMessage,
      EnrollmentErrorType.unknown => l10n.enrollmentErrorUnknownMessage,
    };
  }

  EteeloErrorType get _viewType {
    return switch (type) {
      EnrollmentErrorType.network => EteeloErrorType.network,
      EnrollmentErrorType.unauthorized => EteeloErrorType.unauthorized,
      EnrollmentErrorType.forbidden => EteeloErrorType.forbidden,
      EnrollmentErrorType.server => EteeloErrorType.server,
      EnrollmentErrorType.unknown => EteeloErrorType.unknown,
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
