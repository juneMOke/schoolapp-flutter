import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// État d'erreur de la liste des cas disciplinaires : réutilise l'anatomie
/// partagée [EteeloErrorResult] (4 types). Convention : 401 ->
/// `invalidCredentials`, 403 -> `forbidden`.
class DisciplinaryCaseResultsErrorState extends StatelessWidget {
  final DisciplinaryCaseErrorType type;
  final VoidCallback? onRetry;
  final VoidCallback? onReconnect;
  final VoidCallback? onContactAdmin;

  const DisciplinaryCaseResultsErrorState({
    super.key,
    required this.type,
    this.onRetry,
    this.onReconnect,
    this.onContactAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final viewType = _viewType;
    final action = _primaryAction(l10n, viewType);

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
      autofocusPrimaryAction: action != null,
      fullWidthCard: true,
    );
  }

  EteeloErrorType get _viewType => switch (type) {
    DisciplinaryCaseErrorType.network => EteeloErrorType.network,
    DisciplinaryCaseErrorType.forbidden => EteeloErrorType.forbidden,
    DisciplinaryCaseErrorType.invalidCredentials ||
    DisciplinaryCaseErrorType.unauthorized ||
    DisciplinaryCaseErrorType.auth => EteeloErrorType.unauthorized,
    DisciplinaryCaseErrorType.server ||
    DisciplinaryCaseErrorType.storage => EteeloErrorType.server,
    DisciplinaryCaseErrorType.notFound ||
    DisciplinaryCaseErrorType.validation ||
    DisciplinaryCaseErrorType.none ||
    DisciplinaryCaseErrorType.unknown => EteeloErrorType.unknown,
  };

  _ErrorAction? _primaryAction(
    AppLocalizations l10n,
    EteeloErrorType viewType,
  ) {
    return switch (viewType) {
      EteeloErrorType.forbidden =>
        onContactAdmin == null
            ? null
            : _ErrorAction(
                label: l10n.disciplinaryErrorContactAdmin,
                icon: Icons.mail_outline_rounded,
                onPressed: onContactAdmin!,
              ),
      EteeloErrorType.unauthorized =>
        onReconnect == null
            ? null
            : _ErrorAction(
                label: l10n.disciplinaryErrorReconnect,
                icon: Icons.lock_open_rounded,
                onPressed: onReconnect!,
              ),
      EteeloErrorType.network ||
      EteeloErrorType.server ||
      EteeloErrorType.unknown =>
        onRetry == null
            ? null
            : _ErrorAction(
                label: l10n.disciplinaryErrorRetry,
                icon: Icons.refresh_rounded,
                onPressed: onRetry!,
              ),
    };
  }

  String _title(AppLocalizations l10n, EteeloErrorType viewType) =>
      switch (viewType) {
        EteeloErrorType.network => l10n.disciplinaryErrorNetworkTitle,
        EteeloErrorType.unauthorized => l10n.disciplinaryErrorUnauthorizedTitle,
        EteeloErrorType.forbidden => l10n.disciplinaryErrorForbiddenTitle,
        EteeloErrorType.server => l10n.disciplinaryErrorServerTitle,
        EteeloErrorType.unknown => l10n.disciplinaryErrorUnknownTitle,
      };

  String _message(AppLocalizations l10n, EteeloErrorType viewType) =>
      switch (viewType) {
        EteeloErrorType.network => l10n.disciplinaryCasesNetworkError,
        EteeloErrorType.unauthorized =>
          l10n.disciplinaryCasesInvalidCredentialsError,
        EteeloErrorType.forbidden => l10n.disciplinaryCasesUnauthorizedError,
        EteeloErrorType.server => l10n.disciplinaryCasesServerError,
        EteeloErrorType.unknown => l10n.disciplinaryCasesUnknownError,
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
