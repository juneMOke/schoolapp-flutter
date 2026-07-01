import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/cours_notation_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// État d'erreur de la page détail d'un cours : réutilise l'anatomie partagée
/// [EteeloErrorResult]. Réduit [CoursNotationErrorType] aux familles d'affichage.
///
/// Convention projet : HTTP 401 → session expirée (Se reconnecter) ; HTTP 403 →
/// accès refusé (Contacter l'administrateur, jamais « Réessayer »).
class CoursNotationResultsErrorState extends StatelessWidget {
  final CoursNotationErrorType type;
  final String? incidentCode;
  final VoidCallback? onRetry;
  final VoidCallback? onReconnect;
  final VoidCallback? onContactAdmin;

  const CoursNotationResultsErrorState({
    super.key,
    required this.type,
    this.incidentCode,
    this.onRetry,
    this.onReconnect,
    this.onContactAdmin,
  });

  EteeloErrorType get _viewType => switch (type) {
    CoursNotationErrorType.network => EteeloErrorType.network,
    CoursNotationErrorType.invalidCredentials ||
    CoursNotationErrorType.auth => EteeloErrorType.unauthorized,
    CoursNotationErrorType.forbidden => EteeloErrorType.forbidden,
    CoursNotationErrorType.server ||
    CoursNotationErrorType.storage => EteeloErrorType.server,
    CoursNotationErrorType.notFound ||
    CoursNotationErrorType.validation ||
    CoursNotationErrorType.none ||
    CoursNotationErrorType.unknown => EteeloErrorType.unknown,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final viewType = _viewType;
    final isNotFound = type == CoursNotationErrorType.notFound;
    final action = _primaryAction(l10n, viewType);
    final incidentCodeLabel =
        viewType == EteeloErrorType.server &&
            incidentCode != null &&
            incidentCode!.trim().isNotEmpty
        ? l10n.myCoursesErrorIncidentCode(incidentCode!)
        : null;

    return EteeloErrorResult(
      type: viewType,
      title: isNotFound
          ? l10n.courseDetailErrorNotFoundTitle
          : _title(l10n, viewType),
      message: isNotFound
          ? l10n.courseDetailErrorNotFoundMessage
          : _message(l10n, viewType),
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
        EteeloErrorType.network => l10n.courseDetailErrorNetworkMessage,
        EteeloErrorType.unauthorized =>
          l10n.courseDetailErrorUnauthorizedMessage,
        EteeloErrorType.forbidden => l10n.courseDetailErrorForbiddenMessage,
        EteeloErrorType.server => l10n.courseDetailErrorServerMessage,
        EteeloErrorType.unknown => l10n.courseDetailErrorUnknownMessage,
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
