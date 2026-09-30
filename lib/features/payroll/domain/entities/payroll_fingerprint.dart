import 'package:equatable/equatable.dart';

/// Les totaux d'une devise : brut, retenues d'avance, net. Centimes.
class PayrollTotal extends Equatable {
  final String currency;
  final int grossInCents;
  final int advanceInCents;
  final int netInCents;

  const PayrollTotal({
    required this.currency,
    required this.grossInCents,
    required this.advanceInCents,
    required this.netInCents,
  });

  @override
  List<Object?> get props => [
    currency,
    grossInCents,
    advanceInCents,
    netInCents,
  ];
}

/// Une ligne réduite à ce que l'empreinte compare.
class PayrollDigestLine extends Equatable {
  final String staffMemberId;
  final String currency;
  final int grossInCents;
  final int advanceInCents;
  final int netInCents;

  const PayrollDigestLine({
    required this.staffMemberId,
    required this.currency,
    required this.grossInCents,
    required this.advanceInCents,
    required this.netInCents,
  });

  /// `{staffMemberId}|{currency}|{gross}|{advance}|{net}` — la forme exacte du
  /// contrat, entiers en base 10 sans séparateur.
  String get canonical =>
      '${staffMemberId.toLowerCase()}|$currency|$grossInCents|'
      '$advanceInCents|$netInCents';

  @override
  List<Object?> get props => [
    staffMemberId,
    currency,
    grossInCents,
    advanceInCents,
    netInCents,
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

  const PayrollFingerprint({
    required this.lineCount,
    required this.totals,
    required this.linesDigest,
    this.lines = const [],
  });

  @override
  List<Object?> get props => [lineCount, totals, linesDigest, lines];
}
