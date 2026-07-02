import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// État d'erreur du chargement de la grille de saisie : réutilise l'anatomie
/// partagée [EteeloErrorResult] et réduit [SaisieNotesErrorType] aux familles
/// d'affichage (comme `CoursNotationResultsErrorState`).
///
/// Convention projet : HTTP 401 → session expirée (Se reconnecter) ; HTTP 403 →
/// accès refusé (Contacter l'administrateur, jamais « Réessayer »).
class EvalSaisieResultsErrorState extends StatelessWidget {
  final SaisieNotesErrorType type;
  final VoidCallback? onRetry;
  final VoidCallback? onReconnect;
  final VoidCallback? onContactAdmin;

  const EvalSaisieResultsErrorState({
    super.key,
    required this.type,
    this.onRetry,
    this.onReconnect,
    this.onContactAdmin,
  });

  EteeloErrorType get _viewType => switch (type) {
    SaisieNotesErrorType.network => EteeloErrorType.network,
    SaisieNotesErrorType.invalidCredentials ||
    SaisieNotesErrorType.auth => EteeloErrorType.unauthorized,
    SaisieNotesErrorType.forbidden => EteeloErrorType.forbidden,
    SaisieNotesErrorType.server ||
    SaisieNotesErrorType.storage => EteeloErrorType.server,
    SaisieNotesErrorType.notFound ||
    SaisieNotesErrorType.validation ||
    SaisieNotesErrorType.none ||
    SaisieNotesErrorType.unknown => EteeloErrorType.unknown,
  };

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
          : EteeloButton.primary(
              label: action.label,
              icon: action.icon,
              onPressed: action.onPressed,
              fullWidth: false,
            ),
      autofocusPrimaryAction: action != null,
      fullWidthCard: true,
    );
  }

  _ErrorAction? _primaryAction(
    AppLocalizations l10n,
    EteeloErrorType viewType,
  ) {
    return switch (viewType) {
      // 403 ne propose jamais « Réessayer » : seul le contact est pertinent.
      EteeloErrorType.forbidden =>
        onContactAdmin == null
            ? null
            : _ErrorAction(
                label: l10n.myCoursesErrorContactAdmin,
                icon: Icons.mail_outline_rounded,
                onPressed: onContactAdmin!,
              ),
      EteeloErrorType.unauthorized =>
        onReconnect == null
            ? null
            : _ErrorAction(
                label: l10n.myCoursesErrorReconnect,
                icon: Icons.lock_open_rounded,
                onPressed: onReconnect!,
              ),
      EteeloErrorType.network ||
      EteeloErrorType.server ||
      EteeloErrorType.unknown =>
        onRetry == null
            ? null
            : _ErrorAction(
                label: l10n.myCoursesErrorRetry,
                icon: Icons.refresh_rounded,
                onPressed: onRetry!,
              ),
    };
  }

  String _title(AppLocalizations l10n, EteeloErrorType viewType) =>
      switch (viewType) {
        EteeloErrorType.network => l10n.myCoursesErrorNetworkTitle,
        EteeloErrorType.unauthorized => l10n.myCoursesErrorUnauthorizedTitle,
        EteeloErrorType.forbidden => l10n.myCoursesErrorForbiddenTitle,
        EteeloErrorType.server => l10n.myCoursesErrorServerTitle,
        EteeloErrorType.unknown => l10n.myCoursesErrorUnknownTitle,
      };

  String _message(AppLocalizations l10n, EteeloErrorType viewType) =>
      switch (viewType) {
        EteeloErrorType.network => l10n.evalSaisieErrorNetworkMessage,
        EteeloErrorType.unauthorized => l10n.evalSaisieErrorUnauthorizedMessage,
        EteeloErrorType.forbidden => l10n.evalSaisieErrorForbiddenMessage,
        EteeloErrorType.server => l10n.evalSaisieErrorServerMessage,
        EteeloErrorType.unknown => l10n.evalSaisieErrorUnknownMessage,
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
