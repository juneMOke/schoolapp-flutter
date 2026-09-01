/// Le code d'une ligne de grille — et la seule question qu'on lui pose :
/// **distingue-t-il quelque chose ?**
///
/// Depuis V94, un niveau porte plusieurs lignes d'une même nature — un minerval
/// en sept tranches — et c'est leur `code` qui les départage (« T1 », « T2 »).
/// Mais le serveur **retombe sur la nature** quand l'école n'en saisit pas
/// (`FeeTariffService.codeOuDefaut`) : une grille simple reçoit donc un code qui
/// vaut `TUITION`, techniquement présent et informativement vide.
///
/// Vue de la tablette, cette valeur est indiscernable d'une absence, et c'est
/// pour ça que la règle vit ici plutôt que dans chaque écran : les six points
/// d'affichage — et le ticket imprimé, qui n'a pas de `l10n` — doivent tous
/// trancher pareil. Un seul d'entre eux qui l'oublierait afficherait
/// « Minerval (TUITION) » partout.
library;

/// Le code s'il distingue vraiment cette ligne de ses voisines, `null` sinon.
///
/// Trois façons de ne rien distinguer : absent, vide, ou **égal à la nature**.
/// La comparaison ignore la casse et les espaces de bord — le serveur normalise
/// en majuscules, mais rien n'oblige une base ancienne ou un import à l'avoir
/// fait, et la règle doit trancher sur le sens, pas sur l'orthographe.
String? meaningfulTariffCode({required String? code, required String feeCode}) {
  final trimmed = code?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  if (trimmed.toUpperCase() == feeCode.trim().toUpperCase()) return null;
  return trimmed;
}
