/// Les causes de refus que le serveur nomme dans `detailCode` d'un 422, sur le
/// push d'un versement.
///
/// Miroir du back. Se brancher sur **ces valeurs**, jamais sur le message :
/// celui-ci est rédigé pour un humain et se reformule sans préavis.
///
/// ## Ce que chacune veut dire au guichet
///
/// L'enjeu n'est pas cosmétique : ce classement décide si un encaissement
/// **repart tout seul** ou s'immobilise en `SYNC_ERROR`. L'argent est déjà dans
/// le tiroir et le reçu déjà imprimé — se tromper de côté coûte, dans un sens
/// comme dans l'autre.
abstract final class FinanceErrorCodes {
  /// Le total déclaré n'égale pas la somme des imputations — **devise par
  /// devise** depuis le multi-devise. Un total juste globalement mais mal
  /// réparti est refusé.
  ///
  /// Défaut de composition : la modale a calculé faux, et aucune attente ne le
  /// corrigera. Le fail-fast local existe précisément pour qu'il n'arrive
  /// jamais jusqu'ici.
  static const String allocationSumMismatch = 'ALLOCATION_SUM_MISMATCH';

  /// Une imputation vise une créance libellée dans une autre devise.
  ///
  /// Même nature : le panier désigne une créance qu'il n'aurait pas dû, et le
  /// rejeu donnerait le même refus.
  static const String chargeCurrencyMismatch = 'CHARGE_CURRENCY_MISMATCH';

  /// Aucune créance de ce poste pour cet élève et cette année.
  ///
  /// ⚠️ **Transitoire, et c'est le classement qui compte.** Sur le chemin de
  /// synchro, le serveur remappe par `studentId + feeCode`
  /// (`Policy.REMAP_BY_FEE_CODE`) : ne rien trouver signifie le plus souvent que
  /// **l'inscription de l'élève n'est pas encore remontée**, donc que ses
  /// créances n'existent pas encore côté serveur. Le paiement repartira seul au
  /// cycle suivant.
  ///
  /// Le figer en `SYNC_ERROR` immobiliserait de l'argent qui n'avait qu'à
  /// attendre. C'est le cas que la boutique documente déjà : « l'inscription du
  /// bénéficiaire n'est pas encore partie, la vente repartira seule ».
  static const String unknownFeeCode = 'UNKNOWN_FEE_CODE';

  /// Deux créances partagent ce poste pour cet élève et cette année.
  ///
  /// Frais ad hoc hors périmètre V1 : le serveur refuse d'imputer au hasard.
  /// Aucune attente ne lève l'ambiguïté — il faut corriger la grille.
  static const String ambiguousFeeCode = 'AMBIGUOUS_FEE_CODE';

  /// L'id de créance fourni est introuvable pour cet élève et cette année.
  ///
  /// **N'arrive pas sur le chemin hors ligne** : le serveur n'honore l'id fourni
  /// que sur la route back-office (`Policy.HONOR_PROVIDED_ID`), là où il vient
  /// d'un écran en ligne. Le push de synchro remappe par clé métier et lève
  /// [unknownFeeCode] à la place.
  ///
  /// Déclarée quand même : le catalogue de codes est celui du serveur, et un
  /// client qui ne connaît que la moitié des causes affiche « contactez le
  /// support » pour l'autre.
  static const String unknownStudentCharge = 'UNKNOWN_STUDENT_CHARGE';

  /// Le perçu déclaré, une fois converti au taux fourni, n'éteint pas ce qui
  /// est dû. Vérifié **par devise pivot** et à une unité d'affichage près
  /// (1 FC, 0,01 $) : un excédent sur un pivot ne compense pas un manque sur un
  /// autre.
  ///
  /// Défaut de composition, exactement comme [allocationSumMismatch] : le rejeu
  /// donnerait le même refus. `TenderComposition.check` existe pour que ce refus
  /// n'arrive jamais jusqu'ici — s'il tombe, c'est que le fail-fast local a un
  /// trou, pas que le guichet a mal compté.
  static const String tenderSumMismatch = 'TENDER_SUM_MISMATCH';

  /// Le pivot déclaré n'est soldé par aucune imputation du versement.
  ///
  /// La ligne dit « ces francs éteignent une créance en dollars » quand aucune
  /// imputation du versement ne porte sur des dollars. Le panier désigne un
  /// pivot qu'il n'aurait pas dû : aucune attente ne lève cela.
  static const String unknownTenderPivot = 'UNKNOWN_TENDER_PIVOT';

  /// L'agrégat a été **supprimé côté serveur** : le recréer défairait une purge
  /// que quelqu'un a instruite.
  ///
  /// Rendu avec un `410 Gone`, et non un 4xx ordinaire : le poste doit en tirer
  /// une conséquence définitive plutôt que d'attendre. Ni transitoire — rejouer
  /// donnera toujours le même refus — ni défaut de composition : le versement
  /// était juste, c'est sa contrepartie serveur qui n'existe plus.
  static const String aggregateTombstoned = 'AGGREGATE_TOMBSTONED';

  /// Vrai si la cause peut se résoudre **en attendant**, sans geste au guichet.
  ///
  /// Le POST est idempotent sur `payment.id` : rejouer ne compte jamais l'argent
  /// deux fois, donc le doute profite au rejeu. En cas d'erreur d'appréciation,
  /// le poison finit de toute façon par surfacer un `SYNC_ERROR` — alors qu'un
  /// `failed` prématuré, lui, ne se répare qu'à la main.
  static bool isTransient(String? detailCode) =>
      detailCode == unknownFeeCode || detailCode == unknownStudentCharge;

  /// Vrai si la cause est un défaut de composition du versement, donc à
  /// corriger dans l'application ou au guichet, jamais en attendant.
  static bool isClientDefect(String? detailCode) =>
      detailCode == allocationSumMismatch ||
      detailCode == chargeCurrencyMismatch ||
      detailCode == ambiguousFeeCode ||
      detailCode == tenderSumMismatch ||
      detailCode == unknownTenderPivot;
}
