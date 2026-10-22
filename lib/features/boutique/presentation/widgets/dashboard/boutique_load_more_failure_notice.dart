import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « La suite n'a pas pu être chargée » — sous une liste qui, sans ce mot, se
/// lirait comme complète.
///
/// Un bandeau et non l'état d'erreur plein : les élèves déjà affichés restent
/// justes, seule la suite manque.
class BoutiqueLoadMoreFailureNotice extends StatelessWidget {
  final Failure failure;

  const BoutiqueLoadMoreFailureNotice({super.key, required this.failure});

  /// Réessayer a un sens, sauf pour un droit retiré (403) ou une session
  /// tombée (401) : rejouer ne rendrait ni l'un ni l'autre.
  static bool canRetry(Failure failure) =>
      switch (EteeloErrorType.fromFailure(failure)) {
        EteeloErrorType.forbidden || EteeloErrorType.unauthorized => false,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloNotice.error(switch (EteeloErrorType.fromFailure(failure)) {
      EteeloErrorType.network => l10n.boutiqueBeneficiariesLoadMoreOffline,
      EteeloErrorType.forbidden => l10n.boutiqueBeneficiariesLoadMoreForbidden,
      EteeloErrorType.unauthorized =>
        l10n.boutiqueBeneficiariesLoadMoreUnauthorized,
      _ => l10n.boutiqueBeneficiariesLoadMoreFailed,
    });
  }
}
