import 'package:school_app_flutter/features/academics/domain/entities/sujet/remise_devoir.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La remise en une ligne : « En ligne · avant 17:30 · retard accepté ».
String remiseSummary(AppLocalizations l10n, RemiseDevoir remise) => [
  remise.enLigne ? l10n.remiseModeEnLigne : l10n.remiseModeEnClasse,
  switch (remise.heureLimite) {
    final heure? => l10n.remiseAvant(heure),
    null => l10n.remiseFinDuJour,
  },
  if (remise.enLigne && remise.depotTardifPermis) l10n.remiseRetardAccepte,
].join(' · ');
