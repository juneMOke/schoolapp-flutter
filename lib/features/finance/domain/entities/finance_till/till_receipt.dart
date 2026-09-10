import 'package:equatable/equatable.dart';

/// Une **ligne d'encaissement** de la fenêtre, nommément — la preuve.
///
/// ⚠️ **L'unité est la ligne, pas le reçu.** Un versement qui a pris des francs
/// *et* des dollars apparaît **deux fois sous le même numéro**, et ce n'est pas
/// un doublon : c'est ce que le caissier retrouve dans son tiroir. La caisse
/// d'une ligne est sa [currency] — pas la devise du frais, pas celle de
/// l'élève, et pas « une devise du reçu », qui n'existe pas.
///
/// C'est le seul bloc nominatif de l'écran, et il porte sa **propre permission**
/// côté serveur : lire le pilotage (`finance.stats.read`) ne donne pas le droit
/// de lire les noms, qui demandent en plus `finance.payment.read`. Un refus sur
/// cette table n'est donc pas un refus d'écran.
class TillReceipt extends Equatable {
  /// L'identifiant technique du versement. **Jamais affiché** : il sert de clé
  /// de liste, rien d'autre. Ce que le caissier lit est [receiptNumber].
  final String paymentId;

  /// L'instant de l'encaissement, tel que le serveur l'a daté.
  final DateTime paidAt;

  /// Le **numéro scellé** de la pièce, lu tel quel et **jamais reconstruit**.
  ///
  /// Gabarit réel `[CODE_ETAB]-[TYPE]-[ANNEE_SCOL]-[SEQUENCE]` : code
  /// d'établissement de longueur variable, type sur deux lettres — `RC`
  /// paiement, `RV` vente boutique —, code d'année **scolaire** sur quatre
  /// chiffres (`2526` pour 2025-2026, il enjambe deux millésimes), séquence sur
  /// six chiffres. Exemple : `ETL-RC-2526-000087`.
  ///
  /// ⚠️ `ETL` **n'est pas un code** : c'est le repli appliqué tant qu'aucun
  /// point d'entrée n'écrit le code de l'école. Ne jamais le coder en dur, ne
  /// jamais recomposer un numéro à partir de ses morceaux : ce qui s'affiche est
  /// ce que la pièce porte.
  ///
  /// **`null` est un cas normal** : un versement antérieur à l'imprimerie n'a
  /// pas de numéro scellé. On affiche alors un tiret — jamais l'identifiant
  /// technique à la place.
  final String? receiptNumber;

  /// L'élève au nom de qui le versement a été fait. `null` sur une vente
  /// boutique, qui ne désigne personne.
  final String? studentName;

  /// Sa classe. `null` pour la même raison.
  final String? classroom;

  /// Le caissier qui a encaissé. **`null` quand l'annuaire ne résout pas** —
  /// compte supprimé, ou écriture système : on affiche un tiret, une
  /// attribution inventée étant pire qu'absente.
  final String? collectedBy;

  /// `FACTURATION` ou `BOUTIQUE`. En V1 toutes les lignes valent facturation :
  /// les ventes boutique ne traversent pas la frontière qui les sépare de la
  /// finance.
  final String source;

  /// Le **montant net conservé**, en centimes, exprimé en [currency] : 120 000
  /// tendus dont 5 000 rendus s'écrivent 115 000. Sans quoi le total ne retombe
  /// pas sur le comptage du tiroir.
  final int amount;

  /// La devise **réellement tendue** — celle qui range la ligne dans une caisse.
  final String currency;

  /// Ce que la ligne a soldé, en centimes, dans la devise de la **créance**.
  ///
  /// **Lu, jamais dérivé du taux** : diviser le tendu par le taux produirait un
  /// arrondi qui ne retombe pas sur ce que la créance a réellement perdu — or
  /// c'est ce chiffre-là qu'on annonce à qui contrôle son tiroir.
  ///
  /// `null` hors croisement : le frais était fixé dans la devise tendue, et il
  /// n'y a rien à dire de plus.
  final int? settledAmount;

  /// La devise de la créance éteinte. `null` hors croisement.
  final String? settledCurrency;

  /// Le taux appliqué **au moment du paiement**, en micro-unités
  /// (`taux × 1 000 000`) — jamais le taux du jour : cet écran ne projette pas.
  ///
  /// `null` hors croisement.
  final int? rateMicros;

  const TillReceipt({
    required this.paymentId,
    required this.paidAt,
    required this.source,
    required this.amount,
    required this.currency,
    this.receiptNumber,
    this.studentName,
    this.classroom,
    this.collectedBy,
    this.settledAmount,
    this.settledCurrency,
    this.rateMicros,
  });

  /// La ligne a réglé un frais fixé dans une **autre** devise que celle tendue.
  ///
  /// Vrai seulement si le serveur a envoyé **les trois** informations du
  /// croisement. Une mention partielle — un montant sans son taux, un taux sans
  /// son montant — serait une conversion à moitié annoncée, et la doctrine
  /// interdit exactement ça.
  bool get isCrossed =>
      settledAmount != null && settledCurrency != null && rateMicros != null;

  /// Aucune pièce scellée n'a été émise pour ce versement — une saisie de
  /// rattrapage, typiquement un encaissement repris d'un cahier.
  bool get hasNoSealedNumber =>
      receiptNumber == null || receiptNumber!.trim().isEmpty;

  @override
  List<Object?> get props => [
    paymentId,
    paidAt,
    receiptNumber,
    studentName,
    classroom,
    collectedBy,
    source,
    amount,
    currency,
    settledAmount,
    settledCurrency,
    rateMicros,
  ];
}
