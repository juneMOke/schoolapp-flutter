import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce qu'un échec de geste sur un contrat ou une pièce dit à l'utilisateur :
/// hors ligne, sans droit, pièce altérée ou session absente ne se lisent pas
/// pareil.
abstract final class StaffFailureMessages {
  /// Un contrat ou une pièce n'a pas pu s'écrire sur la tablette.
  static String save(
    AppLocalizations l10n,
    Failure? failure, {
    required String fallback,
  }) => switch (failure) {
    AuthFailure() => l10n.staffSaveNoSession,
    _ => fallback,
  };

  /// Une pièce n'a pas pu s'ouvrir.
  static String open(AppLocalizations l10n, Failure? failure) =>
      switch (failure) {
        NetworkFailure() => l10n.staffDocumentOpenOffline,
        UnauthorizedFailure() => l10n.staffDocumentOpenForbidden,
        IntegrityFailure() => l10n.staffDocumentOpenCorrupt,
        _ => l10n.staffDocumentOpenFailed,
      };
}
