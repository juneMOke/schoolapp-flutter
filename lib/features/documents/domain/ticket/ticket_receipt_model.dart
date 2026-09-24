import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_labels.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_lines.dart';

// Les lignes et les libellés vivent dans leurs propres fichiers depuis qu'un
// troisième bloc d'argent est venu s'ajouter — mais ils restent visibles d'ici.
// Une quinzaine de sites construisent `TicketLabels` en n'important que ce
// fichier : les réexporter découpe la source sans faire de churn d'imports, et
// sans imposer à un appelant de savoir dans lequel des trois vit le type qu'il
// nomme.
export 'package:school_app_flutter/features/documents/domain/ticket/ticket_labels.dart';
export 'package:school_app_flutter/features/documents/domain/ticket/ticket_lines.dart';

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
  //
  // L'en-tête complet, une ligne par champ. Chacun est nullable et chacun
  // s'escamote seul : `wrapped('')` rend une liste vide, donc un champ absent ne
  // laisse pas même une ligne d'espaces. Aucune garde à écrire, et une école
  // mal renseignée sort un en-tête plus court, jamais un en-tête troué.
  final String schoolName;

  /// La ligne « localité » — la ville si le référentiel la porte, la commune à
  /// défaut. Nommée d'après ce qu'elle EST plutôt que d'après la colonne qui la
  /// remplit, justement parce que deux colonnes peuvent la remplir.
  final String? schoolLocality;

  final String? schoolAddress;
  final String? schoolEmail;

  /// Le téléphone de l'ÉTABLISSEMENT, imprimé « Tél. Promoteur ».
  final String? schoolPhone;

  /// Le téléphone de la CAISSE, imprimé « Tél. caisse » sur sa propre ligne.
  ///
  /// Deux lignes nommées plutôt qu'un numéro nu : l'en-tête en portait un seul,
  /// sans libellé, et un parent qui a une question de paiement n'avait aucun
  /// moyen de savoir s'il tombait sur le bon poste. Nommer les deux est ce qui
  /// rend le second utile — et ce qui oblige à nommer le premier.
  ///
  /// `null` tant que le serveur ne le sert pas : le gabarit tait alors la ligne,
  /// et l'en-tête reste celui d'avant, au libellé près.
  final String? schoolTillPhone;

  // ── Z2 : l'élève ────────────────────────────────────────────────────────────
  final String studentFullName;
  final String? matriculationNumber;

  /// Le matricule de l'élève pour l'année du versement — imprimé sous le
  /// matricule classique, qui reste.
  ///
  /// ⚠️ Il vient de l'INSCRIPTION, pas de l'élève : un élève réinscrit en a un
  /// par année. `null` quand le niveau est hors catalogue, quand le matricule
  /// classique n'a pas le format attendu, ou quand le versement ne porte aucune
  /// année — trois silences que le gabarit traite de la même façon : pas de
  /// ligne.
  final String? annualMatriculationNumber;

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
  final String reference;

  /// Cette pièce est-elle encore NON scellée ?
  ///
  /// ⚠️ **Lu affirmativement sur l'absence de `payments.receipt_id`, jamais par
  /// négation.** `!aUnNuméroDéfinitif` serait vrai aussi quand aucune ligne
  /// `generated_documents` LOCALE n'existe — cas normal d'un versement encaissé
  /// sur une AUTRE caisse et descendu par pull. La mention « provisoire »
  /// s'imprimerait alors exactement sur les tickets qui doivent être officiels.
  ///
  /// Le dépôt a déjà payé ce défaut dans `PaymentReceiptState`, dont le
  /// commentaire porte la même règle : affirmer, ne pas nier.
  final bool isProvisional;

  final DateTime paidAt;
  final String? cashierFullName;

  /// Le payeur, **quand il y en a un**.
  ///
  /// `null` — jamais `''` — quand personne n'a été nommé : c'est ce que le
  /// gabarit lit pour escamoter le bloc payeur ENTIER plutôt que d'imprimer un
  /// cadre vide. Sur une pièce, une mention laissée vide se lit comme une
  /// mention EFFACÉE et invite à chercher ce qu'on aurait retiré ; mieux vaut
  /// n'avoir rien à lire que quelque chose à interpréter.
  final String? payerFullName;

  /// Le numéro du payeur. **Seul, il garde le bloc** : il a été tapé, donc il
  /// désigne quelqu'un.
  final String? payerPhoneNumber;

  /// Y a-t-il quelqu'un à nommer comme payeur ? Décidé ici plutôt qu'à l'œil du
  /// gabarit, pour que la règle du bloc soit à un seul endroit.
  bool get hasPayer =>
      (payerFullName?.trim().isNotEmpty ?? false) ||
      (payerPhoneNumber?.trim().isNotEmpty ?? false);

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

  /// Le même solde, **détaillé par (nature de frais, devise)**.
  ///
  /// « Il vous reste 10 000 FC et 314 dollars » pose plus de questions qu'elle n'en
  /// résout : le détail EXPLIQUE les deux devises au lieu de les juxtaposer.
  /// C'est la règle que le ticket applique déjà au montant reçu — additionner
  /// des unités différentes imprimerait un chiffre qui n'est l'argent de
  /// personne — et à laquelle le solde avait échappé.
  ///
  /// **Seuls les frais que CE versement a réglés** y figurent — les clés de
  /// [allocations] —, soldés compris, à zéro : un parent qui règle les frais
  /// divers vient chercher leur solde, pas celui de son minerval.
  ///
  /// Le total suit en dernière ligne du bloc quand il additionne quelque chose
  /// — le détail sans total obligerait le parent à additionner, le total sans
  /// détail est ce qu'on lui reproche. Sous une ligne unique qu'il ne ferait
  /// que répéter, le gabarit le tait.
  final List<TicketAllocationLine> remainingByCharge;

  // ── Z6 : ce qui a déjà été versé ────────────────────────────────────────────
  /// Les versements **antérieurs** de l'élève sur l'année, du plus récent au
  /// plus ancien.
  ///
  /// ⚠️ **Le versement courant n'est PAS dans ce champ**, et il est pourtant
  /// imprimé : c'est [printedPayments] qui l'y ajoute. La séparation est
  /// délibérée — ce champ porte ce que la BASE sait d'autre sur cet élève, le
  /// getter porte ce que le PAPIER montre. Poser le versement courant dans le
  /// champ obligerait chaque appelant à ne pas l'oublier, et le premier qui
  /// l'oublierait sortirait un cumul faux sans que rien ne le dise.
  ///
  /// Deux exclusions, et chacune répond à une question qu'un parent pourrait
  /// poser devant le papier :
  ///
  /// - **les versements extournés n'y sont pas** — ils ne comptent plus dans
  ///   les soldes, et les imprimer ferait croire à un argent encore acquis ;
  /// - **l'année est celle du versement** — un arriéré N-1 additionné au versé
  ///   N donnerait un cumul que plus aucun écran ne confirme.
  final List<TicketHistoryEntry> paymentHistory;

  final TicketLabels labels;

  const TicketReceiptModel({
    required this.schoolName,
    this.schoolLocality,
    this.schoolAddress,
    this.schoolEmail,
    this.schoolPhone,
    this.schoolTillPhone,
    required this.studentFullName,
    this.matriculationNumber,
    this.annualMatriculationNumber,
    this.classroomName,
    required this.reference,
    required this.isProvisional,
    required this.paidAt,
    this.cashierFullName,
    this.payerFullName,
    this.payerPhoneNumber,
    required this.tenders,
    this.allocations = const <TicketAllocationLine>[],
    this.remainingBalance,
    this.remainingByCharge = const <TicketAllocationLine>[],
    this.paymentHistory = const <TicketHistoryEntry>[],
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

  /// Les versements de l'année **tels que le bloc les imprime** : ceux de
  /// [paymentHistory] et **celui-ci**, du plus récent au plus ancien.
  ///
  /// ## Inséré à sa date, jamais épinglé en tête
  ///
  /// Le versement courant est presque toujours le plus récent, donc presque
  /// toujours premier — mais « presque » ne suffit pas : la date d'encaissement
  /// est **saisissable au guichet**, et un versement antidaté épinglé en tête
  /// d'une liste qui s'annonce chronologique ferait douter de l'ordre entier.
  /// Il prend donc sa place par comparaison, et passe **devant** les versements
  /// de même date — à date égale, c'est lui qui vient d'avoir lieu.
  ///
  /// ## Il n'entre que s'il a un montant à montrer
  ///
  /// Sans ligne de tiroir, [amountReceived] est vide et la ligne sortirait
  /// **datée mais sans chiffre** : `_addMoneyBag` n'imprime rien d'un sac vide.
  /// Une date seule sur une colonne de montants ne se lit pas ; mieux vaut un
  /// versement de moins qu'une ligne qu'on ne peut pas interpréter.
  List<TicketHistoryEntry> get printedPayments {
    if (amountReceived.isEmpty) return paymentHistory;

    final current = TicketHistoryEntry(
      paidAt: paidAt,
      received: amountReceived,
    );
    final printed = <TicketHistoryEntry>[];
    var placed = false;
    for (final entry in paymentHistory) {
      if (!placed && !entry.paidAt.isAfter(paidAt)) {
        printed.add(current);
        placed = true;
      }
      printed.add(entry);
    }
    if (!placed) printed.add(current);
    return printed;
  }

  /// Le cumul versé sur l'année, **ce ticket compris**, par devise reçue.
  ///
  /// Dérivé des lignes imprimées, jamais recalculé à côté : un parent additionne
  /// ce qu'il lit, et deux chemins de calcul finiraient par diverger. C'est la
  /// même règle que [remainingBalance], qui dérive lui aussi de son détail.
  MoneyBag get printedPaymentsTotal => MoneyBag.of([
    for (final entry in printedPayments) ...entry.received.entries,
  ]);

  @override
  List<Object?> get props => [
    schoolName,
    schoolLocality,
    schoolAddress,
    schoolEmail,
    schoolPhone,
    schoolTillPhone,
    payerFullName,
    payerPhoneNumber,
    studentFullName,
    matriculationNumber,
    annualMatriculationNumber,
    classroomName,
    reference,
    isProvisional,
    paidAt,
    cashierFullName,
    tenders,
    allocations,
    remainingBalance,
    remainingByCharge,
    paymentHistory,
    labels,
  ];
}
