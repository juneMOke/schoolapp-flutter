import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_grouping.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/charge_cascade_allocation.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_charge_entry.dart';
import 'package:school_app_flutter/features/finance/presentation/utils/facturation_collect_payment_utils.dart';

/// Une **nature de frais** à la page d'encaissement, et les tranches qu'elle
/// porte (GE-1).
///
/// Le caissier règle « le minerval » d'un montant ; l'écran ventile sur les
/// tranches. Au lieu de cocher sept lignes et de taper sept montants.
///
/// ## Ce que ce type n'est PAS
///
/// **Il ne remplace pas les [FacturationChargeEntry], il les pilote.** La page
/// garde sa liste plate de tranches : c'est elle qui porte les contrôleurs, qui
/// est disposée, et surtout c'est elle qui produit les imputations envoyées au
/// serveur. Une imputation par créance, avec son `fee_tariff_id` — le contrat de
/// push ne bouge pas d'un octet, et c'est ce qui rend ce chantier tenable sur de
/// l'argent.
///
/// Conséquence de propriété : **ce groupe ne dispose pas ses tranches.** Il ne
/// possède que son propre contrôleur. Les disposer ici les fermerait sous la
/// page, qui les tient encore.
///
/// ## La bascule de source
///
/// Une seule vérité à la fois, comme la ligne le fait déjà entre l'imputé et le
/// comptoir : *on ne recalcule jamais le champ qui a le curseur*.
///
/// - [groupIsSource] vrai — le montant du groupe commande, la cascade écrit les
///   tranches ;
/// - faux — le caissier a déplié et tapé sur une tranche ; les tranches
///   commandent, et le montant du groupe n'est plus que leur somme.
///
/// La bascule est le seul état de ce type. Tout le reste se dérive.
class FacturationChargeGroupEntry {
  /// La nature, normalisée en majuscules.
  final String feeCode;

  /// La devise des créances de ce groupe, normalisée.
  ///
  /// ⚠️ **Elle fait partie de la clé, et c'est délibérément différent de la
  /// fiche.** Là-bas un groupe est une nature, et le multi-devise se rend par
  /// deux jauges. Ici on tape un montant, et un montant a exactement une
  /// devise : un groupe qui en porterait deux ne pourrait pas se régler d'un
  /// chiffre. Celui qui « harmoniserait » les deux clés casserait la saisie.
  final String currency;

  /// Les tranches, **dans l'ordre reçu** — échéance croissante, puis code de
  /// tarif. C'est l'ordre de la cascade : la plus ancienne se solde d'abord.
  final List<FacturationChargeEntry> tranches;

  /// Le montant réglé pour toute la nature, dans la devise de la créance.
  final TextEditingController controller;

  /// Ce que le parent pose sur le comptoir pour cette nature, dans la devise de
  /// règlement. Vide et inutilisé tant que les deux devises sont la même.
  final TextEditingController tenderController;

  /// Le dépliant est-il ouvert ? Purement visuel — la ventilation ne dépend pas
  /// de ce que le caissier regarde.
  bool expanded = false;

  /// Le montant du groupe commande-t-il les tranches ?
  bool groupIsSource = true;

  /// La devise dans laquelle CETTE nature est réglée. `null` = celle de la
  /// créance, c'est-à-dire le cas courant, qui ne coûte rien.
  ///
  /// ⚠️ **Au groupe, et non plus à la tranche** — et c'est une simplification,
  /// pas un raccourci : les tranches d'un groupe partagent forcément la devise
  /// de créance (elle fait partie de la clé), donc une seule conversion et un
  /// seul taux à lire pour le parent, là où l'écran en affichait autant que de
  /// tranches. La valeur est **propagée** aux tranches, qui restent ce qui
  /// produit les lignes de règlement.
  String? _tenderCurrency;

  /// Le dernier champ édité est celui du comptoir.
  bool tenderIsSource = false;

  FacturationChargeGroupEntry({
    required this.feeCode,
    required this.currency,
    required this.tranches,
  }) : controller = TextEditingController(),
       tenderController = TextEditingController();

  /// La devise de règlement effective — celle des créances par défaut.
  String get effectiveTenderCurrency => _tenderCurrency ?? currency;

  /// Vrai quand cette nature convertit : le seul cas à deux champs.
  bool get isConverted => selected && effectiveTenderCurrency != currency;

  /// Pose la devise de règlement, **et la propage aux tranches**.
  ///
  /// La propagation n'est pas cosmétique : ce sont les tranches qui produisent
  /// les `SettlementLine`, donc les tenders envoyés. Une devise posée au groupe
  /// seul ne partirait nulle part.
  void setTenderCurrency(String? value) {
    _tenderCurrency = (value == null || value == currency) ? null : value;
    for (final tranche in tranches) {
      tranche.tenderCurrency = _tenderCurrency;
      // La tranche ne pilote jamais la conversion quand le groupe commande :
      // son montant imputé est la source, son comptoir en découle.
      tranche.tenderIsSource = false;
    }
    if (_tenderCurrency == null) tenderController.clear();
  }

  /// Ce qui est **posé sur le comptoir**, tel que saisi — jamais borné au
  /// restant : le parent pose ce qu'il pose, et l'excédent devient de la monnaie
  /// à rendre.
  int get tenderedCents {
    final parsed = parseAmountToCents(tenderController.text);
    return parsed > 0 ? parsed : 0;
  }

  /// Le même groupe, vu comme la **fiche** le voit.
  ///
  /// Sert à ne pas réécrire deux règles qui existent déjà et qui doivent dire la
  /// même chose des deux côtés du guichet : la désignation
  /// (`chargeGroupDesignation`) et le statut dérivé du composé
  /// (`StudentChargeGroup.status`). Deux jumeaux auraient divergé — c'est
  /// exactement ce que `student_charge_designation.dart` raconte déjà d'une
  /// divergence passée entre le guichet et le wizard.
  StudentChargeGroup get asChargeGroup => StudentChargeGroup(
    feeCode: feeCode,
    charges: [for (final tranche in tranches) tranche.charge],
  );

  /// Une nature qui ne porte qu'une tranche encore due.
  ///
  /// Elle reste une **ligne nue** à l'écran : un dépliant dont le corps répète
  /// son en-tête ferait payer un geste pour ne rien découvrir.
  bool get isSingleTranche => tranches.length == 1;

  /// Le nombre de tranches **encore dues** — pas celui de la fiche.
  ///
  /// ⚠️ La page ne monte que les créances dont le restant est positif. Un
  /// minerval en sept tranches dont quatre sont soldées en porte **trois** ici,
  /// quand la fiche en annonce sept. Les deux comptes sont justes ; ils ne
  /// doivent pas se libeller pareil.
  int get trancheCount => tranches.length;

  /// Ce que ce groupe peut encore absorber, en cents.
  int get capInCents =>
      cascadeCapInCents([for (final t in tranches) t.remainingInCents]);

  /// Ce qui sera réellement imputé, toutes tranches confondues.
  ///
  /// Somme des montants **effectifs** — donc déjà bornés au restant de chaque
  /// tranche. C'est ce chiffre, et pas la saisie brute, qui dit ce que le
  /// versement portera.
  int get allocatedCents {
    var total = 0;
    for (final tranche in tranches) {
      total += tranche.effectiveCents;
    }
    return total;
  }

  /// Le groupe participe-t-il au versement ?
  ///
  /// **Dérivé, jamais stocké.** Un drapeau de sélection propre au groupe serait
  /// une seconde vérité à tenir d'accord avec celle des tranches, et les deux
  /// finiraient par diverger sur le cas où une tranche est décochée à la main.
  bool get selected => tranches.any((tranche) => tranche.selected);

  /// Ventile [rawAmount] sur les tranches, et rend ce qui a été posé.
  ///
  /// **En cascade** : chaque tranche est remplie à son restant exact avant de
  /// passer à la suivante — exact au centime par construction, aucun arrondi où
  /// un centime pourrait se perdre (cf. [cascadeAllocation]).
  ///
  /// Écrire dans un contrôleur ne relance pas `onChanged`, qui ne part que sur
  /// une frappe : la cascade ne se rappelle donc pas elle-même. C'est l'idiome
  /// que la ligne tient déjà entre ses deux champs.
  int applyCascade(String rawAmount) =>
      applyCascadeCents(parseAmountToCents(rawAmount));

  /// La même ventilation, sur un montant **déjà en centimes**.
  ///
  /// C'est le chemin de la conversion : quand le parent règle en dollars, la
  /// page convertit une fois au niveau du groupe, puis ventile le résultat en
  /// devise de créance. Convertir tranche par tranche tronquerait N fois là où
  /// une seule conversion suffit.
  int applyCascadeCents(int amountInCents) {
    final allocations = cascadeAllocation(
      amountInCents: amountInCents,
      remainingInCents: [for (final t in tranches) t.remainingInCents],
    );

    for (var i = 0; i < tranches.length; i++) {
      final tranche = tranches[i];
      final allocated = allocations[i];
      // Une tranche que la cascade n'atteint pas est **décochée**, pas laissée
      // à zéro : une imputation vide ne part pas au serveur, et une case cochée
      // sans montant se lit comme un oubli de saisie.
      tranche.selected = allocated > 0;
      tranche.tenderIsSource = false;
      tranche.writeDerived(
        tranche.controller,
        allocated > 0 ? formatPlainAmount(allocated) : '',
      );
      if (allocated <= 0) tranche.tenderController.clear();
    }
    return allocations.fold(0, (sum, value) => sum + value);
  }

  /// Vide le groupe : plus rien n'est réglé sur cette nature.
  void clear() {
    controller.clear();
    tenderController.clear();
    tenderIsSource = false;
    for (final tranche in tranches) {
      tranche.selected = false;
      tranche.controller.clear();
      tranche.tenderController.clear();
      tranche.tenderIsSource = false;
    }
  }

  /// Écrit le montant imputé de la nature, sans repousser le curseur.
  void writeGroupAmount(int cents) =>
      _writeDerived(controller, cents > 0 ? formatPlainAmount(cents) : '');

  /// Écrit ce que le comptoir reçoit pour la nature. `null` efface.
  void writeTenderAmount(int? cents) => _writeDerived(
    tenderController,
    (cents == null || cents <= 0) ? '' : formatPlainAmount(cents),
  );

  /// Recopie dans le champ du groupe ce que les tranches valent.
  ///
  /// Appelé quand ce sont **elles** qui commandent — le caissier a déplié et
  /// tapé une tranche. Le champ du groupe devient alors un total affiché, et
  /// n'est plus une saisie.
  void reflectFromTranches() {
    final total = allocatedCents;
    _writeDerived(controller, total > 0 ? formatPlainAmount(total) : '');
  }

  /// Même règle que [FacturationChargeEntry.writeDerived] : ne pas réassigner
  /// une valeur identique, qui replacerait le curseur en fin de champ.
  void _writeDerived(TextEditingController target, String text) {
    if (target.text == text) return;
    target.text = text;
  }

  /// **Ne dispose que son propre contrôleur.** Les tranches appartiennent à la
  /// page.
  void dispose() {
    controller.dispose();
    tenderController.dispose();
  }
}

/// Replie les tranches payables sous leur nature, **sans en perdre aucune**.
///
/// La clé est le couple `(fee_code, devise)` — cf. [FacturationChargeGroupEntry.currency].
/// L'ordre des groupes est celui de première apparition, celui des tranches est
/// celui reçu : les deux viennent du DAO, qui groupe et date déjà. Re-trier ici
/// ajouterait une seconde autorité d'ordonnancement pour n'en respecter aucune.
List<FacturationChargeGroupEntry> groupPayableEntries(
  Iterable<FacturationChargeEntry> entries,
) {
  final grouped = <String, List<FacturationChargeEntry>>{};
  final keys = <String, ({String feeCode, String currency})>{};

  for (final entry in entries) {
    final feeCode = entry.charge.feeCode.trim().toUpperCase();
    final currency = CurrencyCode.normalize(entry.charge.currency);
    final key = '$feeCode|$currency';
    keys[key] = (feeCode: feeCode, currency: currency);
    (grouped[key] ??= <FacturationChargeEntry>[]).add(entry);
  }

  return [
    for (final entry in grouped.entries)
      FacturationChargeGroupEntry(
        feeCode: keys[entry.key]!.feeCode,
        currency: keys[entry.key]!.currency,
        tranches: List<FacturationChargeEntry>.unmodifiable(entry.value),
      ),
  ];
}
