/// La règle du **taux de recouvrement**, dite une seule fois pour tout le
/// module.
///
/// ## `(attendu − reste) / attendu`, jamais `perçu / attendu`
///
/// La seconde formule franchit 100 % dès qu'un versement solde la créance d'un
/// autre exercice — le perçu n'est pas plafonné, l'attendu si. C'est déjà la
/// règle du serveur sur `/finance-stats/recovery`, et deux écrans Finances du
/// même produit doivent donner le même chiffre (RECOUVREMENT_PLAN.md, D8).
///
/// ## Le reste vient d'ailleurs, il ne se déduit pas ici
///
/// [remainingInCents] doit être la somme des restes **planchés créance par
/// créance**. Le recalculer en `max(0, attendu − perçu)` sur des totaux
/// reproduirait exactement le défaut que le plancher par créance évite : un
/// élève qui paie 400 sur 300 de scolarité et rien sur 100 de fournitures
/// afficherait un reste nul, et un taux de 100 %.
class RecoveryRate {
  const RecoveryRate._();

  /// Le taux entier, dans `[0, 100]`.
  ///
  /// **100 quand rien n'est attendu**, et non zéro : « rien ne manque » est la
  /// lecture juste d'une créance inexistante. L'écran, lui, doit poser un tiret
  /// plutôt qu'un « 100 % » triomphant — voir [hasNoExpectation].
  static int of({required int expectedInCents, required int remainingInCents}) {
    if (expectedInCents <= 0) return 100;
    final settled = expectedInCents - remainingInCents;
    final rate = (settled * 100 / expectedInCents).round();
    // Le reste est planché à zéro, donc `settled` ne peut pas dépasser
    // l'attendu ; la borne haute est une ceinture, pas un correctif.
    return rate < 0 ? 0 : (rate > 100 ? 100 : rate);
  }

  /// Rien n'était attendu : le taux vaut 100 et ne veut rien dire.
  ///
  /// Nommé ici, une fois, plutôt que redérivé par chaque widget qui affiche un
  /// taux — sur un poste dormant, un « 100 % » serait un contresens.
  static bool hasNoExpectation(int expectedInCents) => expectedInCents <= 0;
}
