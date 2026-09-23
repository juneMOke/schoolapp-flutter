import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';

/// La machine à états du circuit de validation (spec §01), isolée pour être
/// testable seule : une table de transitions, pas un moteur de règles.
///
/// Une seule chaîne, sans seuil ni palier — une demande de 15 $ et une de
/// 900 $ suivent le même chemin. **Toute paire absente de cette table est
/// interdite et ne doit pas être atteignable par l'interface.**
abstract final class ExpenseTransitions {
  /// Ce que chaque statut permet d'atteindre.
  ///
  /// Les retours vers [ExpenseStatus.pending] couvrent deux gestes distincts
  /// qui aboutissent au même état : la **correction** d'une demande refusée ou
  /// retirée par son demandeur, et l'**annulation d'une décision** par la
  /// direction. Le fil les distingue ; la machine à états n'a pas à le faire.
  static const Map<ExpenseStatus, Set<ExpenseStatus>> allowed = {
    ExpenseStatus.pending: {
      ExpenseStatus.approved,
      ExpenseStatus.refused,
      ExpenseStatus.retracted,
    },
    ExpenseStatus.approved: {ExpenseStatus.paid, ExpenseStatus.pending},
    ExpenseStatus.paid: {ExpenseStatus.pending},
    ExpenseStatus.refused: {ExpenseStatus.pending},
    ExpenseStatus.retracted: {ExpenseStatus.pending},
  };

  /// Un geste qui ne change rien n'est pas une transition : il est **inerte**,
  /// jamais une erreur. C'est le rejeu d'une décision déjà appliquée, et le
  /// serveur lui répond 200 sans rien réécrire.
  static bool isAllowed(ExpenseStatus from, ExpenseStatus to) =>
      from == to || (allowed[from]?.contains(to) ?? false);

  /// Le paiement suit l'approbation, jamais l'inverse : aucun écran ne
  /// propose de payer une demande en attente — ce serait décaisser sans
  /// accord.
  static bool canPay(ExpenseStatus from) => from == ExpenseStatus.approved;

  /// Décider ne se fait que sur une demande en attente.
  static bool canDecide(ExpenseStatus from) => from == ExpenseStatus.pending;

  /// Corriger et renvoyer : le demandeur reprend la main sur une demande
  /// refusée ou retirée.
  static bool canResubmit(ExpenseStatus from) =>
      from == ExpenseStatus.refused || from == ExpenseStatus.retracted;

  /// Annuler une décision — direction seule, et seulement sur une demande
  /// déjà tranchée.
  static bool canReopen(ExpenseStatus from) =>
      from == ExpenseStatus.approved ||
      from == ExpenseStatus.paid ||
      from == ExpenseStatus.refused;

  /// Le retour en attente efface la décision, la date de règlement et le
  /// compteur de relances — mais **jamais le fil** : l'historique reste
  /// lisible, seule la situation courante est réécrite.
  static bool clearsDecision(ExpenseStatus to) => to == ExpenseStatus.pending;

  /// Un refus sans motif laisse le demandeur sans issue : l'interface
  /// l'interdit, et le serveur aussi (`422 REASON_REQUIRED`).
  static bool requiresReason(ExpenseStatus to) => to == ExpenseStatus.refused;
}
