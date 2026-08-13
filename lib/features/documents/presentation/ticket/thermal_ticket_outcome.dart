import 'package:school_app_flutter/core/error/failures.dart';

/// Ce qu'il est advenu d'une tentative d'impression thermique.
///
/// Trois issues, et **l'appelant doit les traiter différemment** — c'est toute
/// la raison de ce type plutôt qu'un `bool`. Un booléen forcerait à confondre
/// « le caissier a renoncé » avec « la machine n'a pas répondu », et le repli
/// PDF s'ouvrirait alors sous les doigts de quelqu'un qui vient d'appuyer sur
/// Annuler.
sealed class ThermalTicketOutcome {
  const ThermalTicketOutcome();
}

/// Le ticket est sorti. Rien à dire, rien à replier.
class ThermalTicketPrinted extends ThermalTicketOutcome {
  const ThermalTicketPrinted();
}

/// Le caissier a fermé la liste sans choisir.
///
/// ⚠️ **Pas un échec** : ne déclenche ni message ni repli. Le geste demandé
/// était « imprimer », il a été repris — insister en ouvrant le spouleur
/// système serait faire exactement ce qu'on vient de refuser.
class ThermalTicketCancelled extends ThermalTicketOutcome {
  const ThermalTicketCancelled();
}

/// Il n'y a plus d'interface pour demander au caissier quelle imprimante.
///
/// Distinct de [ThermalTicketCancelled] : personne n'a renoncé, c'est la modale
/// qui a disparu pendant la préparation. Le geste demandé — imprimer — tient
/// toujours, et le repli PDF n'a besoin d'aucun widget pour l'honorer. Sans ce
/// cas, l'appui ne produisait **rien du tout**, sur un versement déjà encaissé
/// et sans chemin de réimpression.
///
/// Aucune cause n'est annoncée : il n'y a rien à reprocher au matériel, et le
/// caissier n'a plus l'écran sous les yeux.
class ThermalTicketNoSurface extends ThermalTicketOutcome {
  const ThermalTicketNoSurface();
}

/// La thermique n'a pas pu recevoir le ticket.
///
/// [problem] porte la cause exacte, parce que le geste qu'elle appelle diffère :
/// accorder une permission, allumer le Bluetooth, appairer une imprimante,
/// rallumer la machine. C'est le seul cas qui dit la cause **puis** replie sur
/// le PDF.
class ThermalTicketFailed extends ThermalTicketOutcome {
  final ThermalPrinterProblem problem;

  const ThermalTicketFailed(this.problem);
}
