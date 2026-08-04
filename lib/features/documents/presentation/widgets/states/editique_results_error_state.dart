import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_error_type.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// État d'erreur d'une émission de pièce — anatomie partagée
/// [EteeloErrorResult] pilotée par le type d'erreur (règle non-négociable #10).
///
/// Deux cas ne proposent **jamais** de reprise :
///  - `forbidden` (403), comme partout dans l'application : l'accès est refusé
///    par les droits, réessayer ne peut rien changer ;
///  - toute pièce non archivée dont l'issue est inconnue. Le serveur consomme
///    un numéro de séquence avant de rendre le PDF, donc un délai dépassé peut
///    laisser une pièce émise. Rejouer en fabriquerait une seconde, numérotée,
///    que le client ne verra jamais.
///
/// C'est [canRetry], calculé par l'état du BLoC, qui tranche — pas ce widget.
class EditiqueResultsErrorState extends StatelessWidget {
  final EditiqueErrorType type;
  final bool canRetry;
  final VoidCallback? onRetry;
  final VoidCallback? onReconnect;

  /// Motif renvoyé par le serveur, en complément du message de famille.
  ///
  /// Ajouté **après** le message d'anatomie, jamais à sa place : la charte
  /// garantit un texte compréhensible dans la langue de l'utilisateur, ce que le
  /// serveur ne garantit pas.
  final String? serverDetail;

  const EditiqueResultsErrorState({
    super.key,
    required this.type,
    required this.canRetry,
    this.onRetry,
    this.onReconnect,
    this.serverDetail,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final action = _primaryAction(l10n);

    return EteeloErrorResult(
      type: _viewType,
      title: _title(l10n),
      message: _messageWithDetail(l10n),
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

  /// Réduit les types métier aux familles de la charte.
  EteeloErrorType get _viewType => switch (type) {
    // Une issue inconnue est un incident de transport : même médaillon que le
    // réseau, message différent.
    EditiqueErrorType.network ||
    EditiqueErrorType.uncertain => EteeloErrorType.network,
    EditiqueErrorType.sessionExpired => EteeloErrorType.unauthorized,
    EditiqueErrorType.forbidden => EteeloErrorType.forbidden,
    EditiqueErrorType.notFound ||
    EditiqueErrorType.invalid ||
    EditiqueErrorType.server => EteeloErrorType.server,
  };

  String _title(AppLocalizations l10n) => switch (type) {
    EditiqueErrorType.network => l10n.editiqueErrorNetworkTitle,
    EditiqueErrorType.uncertain => l10n.editiqueErrorUncertainTitle,
    EditiqueErrorType.sessionExpired => l10n.editiqueErrorSessionExpiredTitle,
    EditiqueErrorType.forbidden => l10n.editiqueErrorForbiddenTitle,
    EditiqueErrorType.notFound => l10n.editiqueErrorNotFoundTitle,
    EditiqueErrorType.invalid => l10n.editiqueErrorInvalidTitle,
    EditiqueErrorType.server => l10n.editiqueErrorServerTitle,
  };

  /// Message de famille, suivi du motif serveur quand il existe.
  String _messageWithDetail(AppLocalizations l10n) {
    final base = _message(l10n);
    final detail = serverDetail?.trim();
    if (detail == null || detail.isEmpty) return base;
    return '$base\n\n${l10n.editiqueErrorServerDetailLabel(detail)}';
  }

  String _message(AppLocalizations l10n) => switch (type) {
    EditiqueErrorType.network => l10n.editiqueErrorNetworkMessage,
    EditiqueErrorType.uncertain => l10n.editiqueErrorUncertainMessage,
    EditiqueErrorType.sessionExpired => l10n.editiqueErrorSessionExpiredMessage,
    EditiqueErrorType.forbidden => l10n.editiqueErrorForbiddenMessage,
    EditiqueErrorType.notFound => l10n.editiqueErrorNotFoundMessage,
    EditiqueErrorType.invalid => l10n.editiqueErrorInvalidMessage,
    EditiqueErrorType.server => l10n.editiqueErrorServerMessage,
  };

  _ErrorAction? _primaryAction(AppLocalizations l10n) {
    if (type == EditiqueErrorType.sessionExpired) {
      if (onReconnect == null) return null;
      return _ErrorAction(
        label: l10n.editiqueErrorReconnectLabel,
        icon: Icons.login_rounded,
        onPressed: onReconnect!,
      );
    }
    if (!canRetry || onRetry == null) return null;
    return _ErrorAction(
      label: l10n.editiqueErrorRetryLabel,
      icon: Icons.refresh_rounded,
      onPressed: onRetry!,
    );
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
