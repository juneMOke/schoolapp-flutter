import 'package:equatable/equatable.dart';

/// Les totaux d'une devise : brut, retenues d'avance, net. Centimes.
///
/// v2 : les retenues fixes (absence, IPR, CNSS, PC/E) et ce qui sera versé ;
/// `null` dans une empreinte v1, qui les omet.
class PayrollTotal extends Equatable {
  final String currency;
  final int grossInCents;
  final int? deductionInCents;
  final int advanceInCents;
  final int netInCents;
  final int? toPayInCents;

  const PayrollTotal({
    required this.currency,
    required this.grossInCents,
    required this.advanceInCents,
    required this.netInCents,
    this.deductionInCents,
    this.toPayInCents,
  });

  @override
  List<Object?> get props => [
    currency,
    grossInCents,
    deductionInCents,
    advanceInCents,
    netInCents,
    toPayInCents,
  ];
}

/// Une ligne réduite à ce que l'empreinte compare.
class PayrollDigestLine extends Equatable {
  final String staffMemberId;
  final String currency;
  final int grossInCents;
  final int advanceInCents;
  final int netInCents;

  /// v2 : les quatre retenues fixes et ce qui sera versé ce mois — la
  /// direction valide le montant qui sortira, pas seulement le net. Zéro et
  /// le net sur une ligne v1.
  final int formulaVersion;
  final int absenceInCents;
  final int iprInCents;
  final int cnssInCents;
  final int childcareInCents;
  final int toPayInCents;

  const PayrollDigestLine({
    required this.staffMemberId,
    required this.currency,
    required this.grossInCents,
    required this.advanceInCents,
    required this.netInCents,
    this.formulaVersion = 1,
    this.absenceInCents = 0,
    this.iprInCents = 0,
    this.cnssInCents = 0,
    this.childcareInCents = 0,
    int? toPayInCents,
  }) : toPayInCents = toPayInCents ?? netInCents;

  /// Absence, IPR, CNSS et PC/E.
  int get fixedDeductionsInCents =>
      absenceInCents + iprInCents + cnssInCents + childcareInCents;

  /// La forme exacte du contrat, entiers en base 10 sans séparateur :
  /// - v1 `{staffMemberId}|{currency}|{gross}|{advance}|{net}` ;
  /// - v2 `{staffMemberId}|{currency}|{gross}|{absence}|{ipr}|{cnss}|{pce}|`
  ///   `{advance}|{net}|{verser}` (`PayrollFingerprint` du serveur).
  String get canonical => formulaVersion < 2
      ? '${staffMemberId.toLowerCase()}|$currency|$grossInCents|'
            '$advanceInCents|$netInCents'
      : '${staffMemberId.toLowerCase()}|$currency|$grossInCents|'
            '$absenceInCents|$iprInCents|$cnssInCents|$childcareInCents|'
            '$advanceInCents|$netInCents|$toPayInCents';

  @override
  List<Object?> get props => [
    staffMemberId,
    currency,
    grossInCents,
    advanceInCents,
    netInCents,
    formulaVersion,
    absenceInCents,
    iprInCents,
    cnssInCents,
    childcareInCents,
    toPayInCents,
  ];
}

/// Ce que la direction (ou l'économe) a vu en confirmant : le nombre de
/// lignes, les totaux par devise, et l'empreinte des lignes. Le serveur
/// recalcule et refuse (`PAYROLL_STALE`) s'il trouve autre chose.
class PayrollFingerprint extends Equatable {
  final int lineCount;

  /// Triés par devise.
  final List<PayrollTotal> totals;

  /// SHA-256 hexadécimal minuscule.
  final String linesDigest;

  /// Les lignes réduites — portées par un refus `PAYROLL_STALE` pour dire
  /// quels agents diffèrent ; vides dans ce que la tablette envoie.
  final List<PayrollDigestLine> lines;

  /// La formule sous laquelle [linesDigest] a été calculé (T6).
  final int formulaVersion;

  const PayrollFingerprint({
    required this.lineCount,
    required this.totals,
    required this.linesDigest,
    this.lines = const [],
    this.formulaVersion = 1,
  });

  @override
  List<Object?> get props => [
    lineCount,
    totals,
    linesDigest,
    lines,
    formulaVersion,
  ];
}
