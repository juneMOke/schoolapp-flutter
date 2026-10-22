import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/features/academics/domain/entities/depot/copie_rendue.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce qu'un élève montre de sa copie : un libellé, et une teinte empruntée aux
/// présences (rendu = présent, en retard = retard, pas rendu = à pointer).
abstract final class DepotLabels {
  static String etat(AppLocalizations l10n, EtatRendu etat) => switch (etat) {
    EtatRendu.rendu => l10n.depotEtatRendu,
    EtatRendu.renduEnRetard => l10n.depotEtatRenduEnRetard,
    EtatRendu.pasRendu => l10n.depotEtatPasRendu,
  };

  static PresenceTone tone(EtatRendu etat) => PresenceTone.of(switch (etat) {
    EtatRendu.rendu => PresenceStatus.present,
    EtatRendu.renduEnRetard => PresenceStatus.late,
    EtatRendu.pasRendu => PresenceStatus.none,
  });
}
