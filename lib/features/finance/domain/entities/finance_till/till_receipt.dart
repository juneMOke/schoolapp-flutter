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

  /// L'identifiant de l'élève — **ce qui rend la fiche ouvrable depuis ici**.
  ///
  /// Le serveur le lit depuis `payments.student_id`, colonne `NOT NULL` : une
  /// ligne de caisse désigne toujours quelqu'un. Il reste néanmoins **nullable
  /// ici**, et c'est délibéré : le champ n'est servi que depuis la version du
  /// contrat qui l'ajoute, et un binaire déployé avant elle doit continuer de
  /// lire la table sans lever. L'œil s'allume alors de lui-même au déploiement
  /// serveur, sans rien coordonner.
  final String? studentId;

  /// Le prénom, le nom et le post-nom, **séparés**.
  ///
  /// [studentName] est un libellé déjà composé, bon pour la colonne « Élève » et
  /// pour rien d'autre : la fiche de facturation exige les composants, et
  /// découper « MAKELA Kevin Mbuyi » serait une invention — l'ordre n'est pas
  /// délimité et le nombre de mots varie (un nom composé, un post-nom absent).
  ///
  /// Ils suivent [studentName] : les quatre manquent ensemble quand l'annuaire
  /// ne résout plus l'élève. C'est ce cas-là qui éteint l'œil.
  final String? firstName;
  final String? lastName;

  /// Le post-nom. **Son absence est ordinaire** et n'empêche rien : la fiche
  /// filtre les composants vides avant de composer le nom qu'elle affiche.
  final String? surname;

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
    this.studentId,
    this.firstName,
    this.lastName,
    this.surname,
    this.collectedBy,
    this.settledAmount,
    this.settledCurrency,
    this.rateMicros,
  });

  /// La ligne porte de quoi ouvrir la fiche de facturation de son élève.
  ///
  /// Trois conditions, et pas une de plus : l'identifiant, le nom, le prénom.
  /// C'est **exactement** la garde que la fiche applique de son côté
  /// (`FacturationDetailIntent.hasStudentIdentity`), reportée ici pour que le
  /// bouton ne promette jamais ce que l'écran suivant refuserait — il rendrait
  /// une carte « contexte indisponible » à la place du grand-livre.
  ///
  /// Le **post-nom n'en fait pas partie** : beaucoup d'élèves n'en ont pas.
  /// Le niveau et le cycle non plus — la fiche s'ouvre sans eux et affiche
  /// « Facturation · - » en sur-titre.
  bool get canOpenFinancialRecord =>
      (studentId?.trim().isNotEmpty ?? false) &&
      (firstName?.trim().isNotEmpty ?? false) &&
      (lastName?.trim().isNotEmpty ?? false);

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
    // ⚠️ Les quatre composants entrent dans l'égalité comme les autres. Un
    // `props` incomplet rendrait deux lignes différentes égales, et ce dépôt a
    // déjà payé cet oubli ailleurs : la cécité se propage ensuite à tout ce qui
    // compare, y compris les tests censés attraper la régression.
    studentId,
    firstName,
    lastName,
    surname,
    collectedBy,
    source,
    amount,
    currency,
    settledAmount,
    settledCurrency,
    rateMicros,
  ];
}
