import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

class Payment extends Equatable {
  final String id;
  final String studentId;
  final String academicYearId;

  /// Ce qui a été encaissé, **une entrée par devise**.
  ///
  /// Le versement portait un montant scalaire ; ce n'en était pas une propriété
  /// mais le résumé de ses imputations, juste tant qu'il n'y avait qu'une
  /// devise. Un passage au guichet qui solde une créance en dollars et une en
  /// francs n'a pas de montant unique — et les additionner donnerait un chiffre
  /// que personne ne peut vérifier.
  final MoneyBag amounts;

  /// Les trois `null` sur un encaissement ANONYME (V114 serveur) : l'argent a
  /// été pris sans nommer qui le donnait, et c'est un cas nominal. `null`,
  /// jamais `''`.
  final String? payerFirstName;
  final String? payerLastName;
  final String? payerMiddleName;

  /// Numéro E.164 du payeur (v28). Nul est un état NORMAL : la saisie l'exige
  /// depuis le palier, mais tout versement plus ancien — et tout versement
  /// scellé avant que le contrat ne le porte — n'en a pas.
  final String? payerPhoneNumber;
  final DateTime paidAt;

  /// Paiement de CE poste pas encore remonté au serveur (FRONT §3). Faux pour
  /// les paiements synchronisés (ce poste ou l'autre poste, arrivés par pull).
  final bool isPendingSync;

  /// Qui a encaissé, tel que le poste l'a stampé à l'encaissement (v19).
  ///
  /// ⚠️ **Nul est un état NORMAL et durable, pas un chargement.** Le nom n'est
  /// écrit que par la tablette qui encaisse, et le pull exclut délibérément
  /// ces colonnes de son patch pour ne pas les écraser — ce qui est imprimé
  /// sur le ticket ne se réécrit pas depuis le réseau. Il est donc vide pour
  /// tout paiement venu d'un autre guichet, pour tout encaissement antérieur à
  /// la v19, et quand l'annuaire local était muet au moment du geste.
  ///
  /// Ce vide-là est désormais comblé par [collectedByName] (v29) : le contrat
  /// de synchro porte l'attribution du SERVEUR, que [cashierFullName] utilise
  /// en repli. Ces deux champs-ci restent, eux, la trace de ce poste.
  final String? cashierFirstName;
  final String? cashierLastName;

  const Payment({
    required this.id,
    required this.studentId,
    required this.academicYearId,
    this.amounts = MoneyBag.empty,
    this.payerFirstName,
    this.payerLastName,
    this.payerMiddleName,
    this.payerPhoneNumber,
    required this.paidAt,
    this.isPendingSync = false,
    this.cashierFirstName,
    this.cashierLastName,
    this.collectedByName,
  });

  /// Nom de l'encaisseur tel que le SERVEUR l'attribue (v29), aplati par le
  /// flux de synchro. Nul pour un versement pas encore remonté.
  final String? collectedByName;

  /// Nom affichable de l'encaisseur, `null` si personne ne l'a nommé.
  ///
  /// Deux sources, dans cet ordre :
  ///  1. ce que CE poste a stampé à l'encaissement (`cashier_*`, v19) ;
  ///  2. à défaut, ce que le serveur attribue (`collectedByName`, v29).
  ///
  /// L'ordre n'est pas arbitraire. Le nom stampé localement est celui qui a été
  /// IMPRIMÉ sur le ticket remis au payeur : le faire remplacer plus tard par
  /// une autre écriture du même nom ferait diverger l'écran du papier que le
  /// payeur a en main. Le second ne comble que le vide — un versement encaissé
  /// à un autre guichet, où rien de local n'a jamais été observé.
  ///
  /// Même règle de composition que le ticket
  /// (`TicketPaymentRow.cashierFullName`) : les deux surfaces montrent le même
  /// nom pour le même versement, ou ne montrent rien.
  String? get cashierFullName {
    final parts = [
      cashierFirstName?.trim(),
      cashierLastName?.trim(),
    ].where((part) => part != null && part.isNotEmpty).cast<String>();
    if (parts.isNotEmpty) return parts.join(' ');
    final attributed = collectedByName?.trim();
    return (attributed == null || attributed.isEmpty) ? null : attributed;
  }

  @override
  List<Object?> get props => [
    id,
    studentId,
    academicYearId,
    amounts,
    payerFirstName,
    payerLastName,
    payerMiddleName,
    collectedByName,
    payerPhoneNumber,
    paidAt,
    isPendingSync,
    cashierFirstName,
    cashierLastName,
  ];
}
