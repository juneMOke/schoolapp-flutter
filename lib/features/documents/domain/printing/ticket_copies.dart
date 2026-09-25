/// Combien d'exemplaires d'un ticket sortir d'un seul geste.
///
/// Les exemplaires sont **strictement identiques** : aucune mention
/// « original » / « copie » n'est imprimée (décision du 2026-09-25, première
/// version). Un exemplaire de plus n'est donc qu'une réimpression anticipée —
/// ce que le bouton « Réimprimer » offre déjà librement.
///
/// ⚠️ La borne haute n'est pas cosmétique : les exemplaires partent **en un
/// seul envoi** (cf. `ThermalPrinterPort.printBytes`), et un compteur sans
/// plafond laisserait une erreur de saisie vider le rouleau au guichet.
abstract final class TicketCopies {
  static const int min = 1;
  static const int max = 5;

  /// Ce qui sort quand personne n'a rien dit — ni le caissier, ni l'école.
  ///
  /// L'école pourra un jour fixer son propre défaut (évolution back à venir,
  /// cf. `TICKET_COPIES_PLAN.md`) ; en attendant, un seul exemplaire, comme
  /// avant l'existence du compteur.
  static const int fallback = 1;

  static int clamp(int value) => value.clamp(min, max);
}
