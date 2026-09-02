import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// Une ligne de **perçu** : ce qui est entré dans le tiroir, dans son unité.
///
/// Complémentaire de [TicketAllocationLine], et dans l'autre devise. Une
/// imputation éteint une créance, donc elle est en devise de créance ; un
/// tender décrit une pile de billets, donc il est en devise reçue. [rateMicros]
/// est le seul nombre qui relie les deux, et il est **gelé** au versement.
class TicketTenderLine extends Equatable {
  /// Le net conservé, jamais le montant présenté.
  final int amountInCents;

  /// La devise reçue.
  final String currency;

  /// Le taux appliqué, en micro-unités. `1 000 000` = perçu et imputé dans la
  /// même unité, ce qui est le cas courant et tout l'historique.
  final int rateMicros;

  /// La devise de la créance contre laquelle ce taux s'applique.
  final String pivotCurrency;

  const TicketTenderLine({
    required this.amountInCents,
    required this.currency,
    this.rateMicros = ExchangeRate.scale,
    required this.pivotCurrency,
  });

  /// Les lignes de perçu d'un versement réglé **dans la devise de la créance** :
  /// une par devise, taux 1.
  ///
  /// C'est le cas courant, et tout l'historique d'avant la V2 — la forme que le
  /// backfill de la v41 écrit en base. Elle ne coûte aucune arithmétique et
  /// n'imprime aucun taux.
  static List<TicketTenderLine> identityFrom(MoneyBag bag) => [
    for (final amount in bag.entries)
      TicketTenderLine(
        amountInCents: amount.amountInCents,
        currency: amount.currency,
        pivotCurrency: amount.currency,
      ),
  ];

  /// Vrai quand cette ligne ne fait que redire l'imputation — le ticket
  /// n'imprime alors **aucun taux** : un « 1,00 » sur un papier de guichet ferait
  /// chercher au parent ce qui a été converti.
  bool get isIdentity =>
      rateMicros == ExchangeRate.scale && currency == pivotCurrency;

  ExchangeRate get rate => ExchangeRate.parse(
    base: pivotCurrency,
    quote: currency,
    rateMicros: rateMicros,
    effectiveFrom: DateTime.utc(1970),
  );

  Money get amount => Money.parse(amountInCents, currency);

  @override
  List<Object?> get props => [
    amountInCents,
    currency,
    rateMicros,
    pivotCurrency,
  ];
}

/// Une ligne de répartition du versement (zone Z5).
class TicketAllocationLine extends Equatable {
  final String label;
  final int amountInCents;

  /// La devise de CETTE imputation : elle solde une créance, donc elle en tient
  /// exactement une. Scalaire, définitivement.
  final String currency;

  const TicketAllocationLine({
    required this.label,
    required this.amountInCents,
    required this.currency,
  });

  @override
  List<Object?> get props => [label, amountInCents, currency];
}

/// Libellés fixes du ticket, injectés depuis `AppLocalizations`.
///
/// Le modèle et son rendu restent **purs** — aucun `BuildContext`, aucune
/// dépendance Flutter — tout en respectant l'interdiction des chaînes en dur :
/// c'est l'appelant qui traduit, le gabarit qui arrange.
class TicketLabels extends Equatable {
  /// Nature de la pièce, imprimée en tête : « Ticket de perception ».
  ///
  /// ⚠️ **Distinct de la « note de perception »** (`EditiqueDocumentType.NP`),
  /// qui est une pièce **annuelle scellée** au niveau élève. Deux objets
  /// différents : celui-ci atteste **le montant reçu** lors d'un encaissement,
  /// trop-perçu ou non — l'imputation exacte appartient au reçu scellé.
  final String documentTitle;

  final String provisionalBanner;
  final String referenceLabel;
  final String cashierLabel;
  final String studentLabel;
  final String matriculationLabel;
  final String classroomLabel;
  final String amountReceivedLabel;

  /// « Taux » — imprimé **seulement** quand perçu et imputé ne sont pas dans la
  /// même unité. C'est le chiffre que le parent conteste au guichet ; le laisser
  /// déduire par division ferait apparaître un taux dérivé de l'arrondi
  /// (2 847,3 là où le caissier a annoncé 2 850), ce qui fait amateur.
  final String rateLabel;

  /// « soit » — coiffe la valeur d'un poste **en devise reçue**, sous son
  /// montant imputé. Sans ce mot, une seconde ligne de chiffres sous la première
  /// se lirait comme un second montant dû.
  final String derivedAmountPrefix;

  final String allocationsLabel;

  /// Part du montant reçu qu'aucune créance n'absorbe — imprimée comme dernière
  /// ligne de la répartition, et seulement quand elle est strictement positive.
  ///
  /// Le ticket **atteste le montant perçu**, il n'arbitre pas son imputation :
  /// c'est le reçu scellé qui fait apparaître le trop-perçu. Ce libellé n'est là
  /// que pour empêcher un écart muet entre le reçu et la ventilation.
  final String advanceLabel;

  final String balanceLabel;

  /// « sous réserve de synchronisation » — n'accompagne QUE le solde.
  final String balanceReservation;

  /// « Conservez ce ticket jusqu'à la remise de votre reçu définitif. »
  final String keepTicketNotice;

  const TicketLabels({
    required this.documentTitle,
    required this.provisionalBanner,
    required this.referenceLabel,
    required this.cashierLabel,
    required this.studentLabel,
    required this.matriculationLabel,
    required this.classroomLabel,
    required this.amountReceivedLabel,
    required this.rateLabel,
    required this.derivedAmountPrefix,
    required this.allocationsLabel,
    required this.advanceLabel,
    required this.balanceLabel,
    required this.balanceReservation,
    required this.keepTicketNotice,
  });

  @override
  List<Object?> get props => [
    documentTitle,
    provisionalBanner,
    referenceLabel,
    cashierLabel,
    studentLabel,
    matriculationLabel,
    classroomLabel,
    amountReceivedLabel,
    rateLabel,
    derivedAmountPrefix,
    allocationsLabel,
    advanceLabel,
    balanceLabel,
    balanceReservation,
    keepTicketNotice,
  ];
}

/// Le reçu provisoire, tel qu'il sera imprimé.
///
/// **Ce n'est pas un fichier** (ADR-012 D-3) : c'est une projection déterministe
/// de lignes SQLite déjà écrites. Tant que la ligne de paiement est en attente
/// de synchro, réimprimer produit exactement le même artefact — c'est ce que
/// garantissent les colonnes stampées à l'encaissement (caissier, appareil,
/// numéro provisoire), et non une quelconque mise en cache.
///
/// Tous les champs d'identité sont **nullables**, et c'est structurel :
/// `students.matriculation_number` est NULL hors ligne par construction (il est
/// attribué à l'ACK), la classe l'est tant que le roster n'a pas été pullé, et
/// le caissier peut ne pas avoir d'identité résoluble. Le gabarit sait taire ce
/// qu'il ne connaît pas — il n'invente jamais.
class TicketReceiptModel extends Equatable {
  // ── Z1 : l'établissement ────────────────────────────────────────────────────
  final String schoolName;
  final String? schoolMunicipality;

  // ── Z2 : l'élève ────────────────────────────────────────────────────────────
  final String studentFullName;
  final String? matriculationNumber;
  final String? classroomName;

  // ── Z3 : la traçabilité ─────────────────────────────────────────────────────
  /// `PROV-<idAppareil>-<uuid>`, en clair. Jamais de QR (Z4) : un code
  /// vérifiable sur une pièce non scellée serait un mensonge.
  ///
  /// ⚠️ **Arbitré le 2026-08-12, ne pas rouvrir sur la seule lecture de
  /// l'ADR-013.** Celui-ci demande un QR portant l'UUID du `Payment`, comme
  /// invariant de construction — « référence, jamais un sceau », donc un
  /// pointeur vers le portail parent, pas une preuve d'authenticité. La
  /// décision retenue est **D-4 (ADR-012)** : le ticket doit rester
  /// délibérément dissemblable du scellé. Un parent qui voit un QR conclut que
  /// le papier est officiel, et la mention « Conservez ce ticket jusqu'à la
  /// remise de votre reçu définitif » perd alors son sens.
  ///
  /// Ajouter un QR ici ne se fait donc qu'après avoir tranché **ce
  /// conflit-là**, pas en appliquant l'ADR-013 à la lettre.
  final String provisionalReference;
  final DateTime paidAt;
  final String? cashierFullName;

  // ── Z5 : l'argent ───────────────────────────────────────────────────────────
  /// Ce qui est entré dans le tiroir, ligne par ligne.
  ///
  /// ⚠️ **C'est la source du « montant reçu », et elle a changé.** Le champ
  /// s'appelait déjà « reçu » mais portait de l'IMPUTÉ — il était alimenté par
  /// `payment.amounts`, qui est en devise de créance. Tant que perçu et imputé
  /// se confondaient, personne ne pouvait le voir ; le jour où un franc règle un
  /// dollar, le ticket annonce « Montant reçu : 30,00 $ » à un parent qui vient
  /// de poser 50 000 FC. Contrairement au reçu scellé, dont l'assertion serveur
  /// refuse de rendre le document, celui-ci **s'imprime, faux**.
  ///
  /// [amountReceived] en dérive désormais, et n'est plus posable à la main :
  /// c'est ce qui rend l'erreur impossible plutôt que déconseillée.
  final List<TicketTenderLine> tenders;

  final List<TicketAllocationLine> allocations;

  /// Solde restant **après** ce versement, tel que le local le compose. `null`
  /// quand il n'est pas calculable : mieux vaut omettre la ligne que d'imprimer
  /// un chiffre faux sur un papier remis à un parent.
  /// Le solde restant, **par devise**. `null` quand il n'est pas calculable —
  /// le ticket omet alors la ligne, ce qu'il sait faire.
  final MoneyBag? remainingBalance;

  final TicketLabels labels;

  const TicketReceiptModel({
    required this.schoolName,
    this.schoolMunicipality,
    required this.studentFullName,
    this.matriculationNumber,
    this.classroomName,
    required this.provisionalReference,
    required this.paidAt,
    this.cashierFullName,
    required this.tenders,
    this.allocations = const <TicketAllocationLine>[],
    this.remainingBalance,
    required this.labels,
  });

  /// Ce que le guichet a reçu, **par devise reçue**.
  ///
  /// Un passage au guichet peut solder une créance en dollars et une en francs :
  /// c'est un acte, donc un versement et un reçu — mais pas un montant unique.
  MoneyBag get amountReceived => MoneyBag.sumBy(
    tenders,
    (tender) => Money.parse(tender.amountInCents, tender.currency),
  );

  /// Le taux à imprimer pour ce pivot, `null` quand il n'y a rien à dire.
  ///
  /// Rien à dire couvre deux cas : le règlement est dans la devise de la créance
  /// (taux 1), ou **deux règlements de devises différentes visent le même
  /// pivot** — le modèle l'autorise, la saisie ne le produit pas, et imprimer
  /// l'un des deux ferait recompter le parent sur un chiffre qui n'explique que
  /// la moitié de la ligne.
  TicketTenderLine? tenderForPivot(String pivotCurrency) {
    final pivot = pivotCurrency.trim().toUpperCase();
    final matching = tenders
        .where((tender) => tender.pivotCurrency == pivot && !tender.isIdentity)
        .toList(growable: false);
    if (matching.length != 1) return null;
    return matching.single;
  }

  /// Ce que ce poste représente **en devise reçue**, `null` quand il n'y a rien
  /// à convertir.
  ///
  /// Dérivé (`allocation × taux`), jamais stocké : un versement de 112 000 FC
  /// qui solde 40 $ et 50 $ n'a pas comporté un paquet de billets pour l'un et
  /// un paquet pour l'autre. Stocker la correspondance enregistrerait une
  /// proration comme si c'était une observation.
  ///
  /// **La dernière ligne d'un pivot absorbe le résidu d'arrondi**, pour que la
  /// colonne dérivée somme exactement au perçu — sans quoi un parent qui
  /// additionne trouve un écart que rien n'explique.
  ///
  /// ⚠️ Cette règle d'absorption doit être **la même que celle du reçu scellé**,
  /// que le serveur compose de son côté : les deux pièces coexistent dans les
  /// mains du même parent. Sens de l'arrondi et ordre de tri restent à confirmer
  /// avec le back (question 4 de `FRONT_TENDERS_PLAN.md`).
  Money? derivedAmountOf(TicketAllocationLine allocation) {
    final pivot = allocation.currency.trim().toUpperCase();
    final tender = tenderForPivot(pivot);
    if (tender == null) return null;

    final ofPivot = allocations
        .where((line) => line.currency.trim().toUpperCase() == pivot)
        .toList(growable: false);
    final isLast = identical(ofPivot.last, allocation);
    if (!isLast) {
      return Money(
        ExchangeRates.convertCents(allocation.amountInCents, tender.rate),
        tender.currency,
      );
    }

    // La dernière absorbe : on lui donne ce qui reste du perçu de ce pivot,
    // et non sa propre conversion.
    final received = tenders
        .where(
          (line) =>
              line.pivotCurrency == pivot && line.currency == tender.currency,
        )
        .fold<int>(0, (sum, line) => sum + line.amountInCents);
    final others = ofPivot
        .take(ofPivot.length - 1)
        .fold<int>(
          0,
          (sum, line) =>
              sum + ExchangeRates.convertCents(line.amountInCents, tender.rate),
        );
    return Money(received - others, tender.currency);
  }

  /// Somme des lignes de répartition. Dérivée, jamais stockée.
  ///
  /// ⚠️ **Peut être inférieure à [amountReceivedInCents]**, et ce n'est pas une
  /// anomalie de composition : un versement qui dépasse le dû est accepté
  /// (`PaymentAnomalyKind.overpayment`), le reçu définitif est scellé, et le
  /// ticket remis au parent reste valide. L'écart s'imprime en « avance ».
  MoneyBag get allocated => MoneyBag.sumBy(
    allocations,
    (line) => Money.parse(line.amountInCents, line.currency),
  );

  /// La part du reçu qu'aucune créance n'absorbe, **en devise reçue**.
  ///
  /// L'unité compte : l'avance est ce qui reste dans le tiroir, donc elle se dit
  /// dans la monnaie que le parent a posée. L'imputé est converti au taux du
  /// versement avant d'être retranché — soustraire des dollars imputés à des
  /// francs reçus donnerait un nombre qui n'est l'argent de personne.
  ///
  /// La soustraction se fait ici et pas dans `MoneyBag` : soustraire deux sacs
  /// en général pose une question sans bonne réponse — que faire d'une devise
  /// présente à droite et pas à gauche ? Ici elle en a une : ce qui est imputé
  /// sans avoir été reçu est une saisie incohérente, pas une avance, et ne
  /// s'imprime pas.
  MoneyBag get advance {
    final imputed = allocated;
    return MoneyBag.of([
      for (final tender in tenders)
        Money(
          tender.amountInCents -
              ExchangeRates.convertCents(
                imputed.amountIn(tender.pivotCurrency)?.amountInCents ?? 0,
                tender.rate,
              ),
          tender.currency,
        ),
    ]).withoutZeros;
  }

  @override
  List<Object?> get props => [
    schoolName,
    schoolMunicipality,
    studentFullName,
    matriculationNumber,
    classroomName,
    provisionalReference,
    paidAt,
    cashierFullName,
    tenders,
    allocations,
    remainingBalance,
    labels,
  ];
}
