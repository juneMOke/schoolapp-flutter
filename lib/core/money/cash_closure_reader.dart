/// Les clôtures de caisse **vivantes**, lues sur la tablette.
///
/// Tenu par la Trésorerie (`treasury_closures`, flux `treasury.closures`) ;
/// lu par les modules qui doivent savoir qu'une journée de caisse est figée
/// avant d'offrir un geste qui la toucherait — l'annulation d'une dépense
/// déclarée (F44), par exemple. Le serveur reste le filet : ce que la
/// tablette ne voit pas encore, il le refuse.
abstract class CashClosureReader {
  /// Une clôture non rouverte de la caisse de [currency] existe-t-elle à
  /// [day] **ou après** ? Une sortie de [day] ne se défait alors plus sans
  /// ajustement de caisse.
  Future<bool> hasLiveClosureFrom(DateTime day, String currency);
}
