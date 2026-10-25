/// Le statut d'une ligne du tableau « Ce que chaque salarié perçoit » —
/// mêmes mots au PDF du serveur (Q7) qu'à l'écran.
enum PayrollDashboardStatus {
  /// Mois non validé : rien n'est versé avant validation.
  toDisburse,
  settled,
  partial,
  due,
}

/// Les filtres du tableau ; la valeur du fil est celle de la route PDF.
enum PayrollDashboardFilter {
  all('ALL'),
  outstanding('OUTSTANDING'),
  settled('SETTLED');

  const PayrollDashboardFilter(this.wire);
  final String wire;

  bool keeps(PayrollDashboardStatus status) => switch (this) {
    all => true,
    // Un brouillon : tout est encore à verser, rien n'est soldé.
    outstanding => status != PayrollDashboardStatus.settled,
    settled => status == PayrollDashboardStatus.settled,
  };
}

/// Une ligne de « Ce que chaque salarié perçoit », définitions figées avec le
/// back (doc back, « P1 : définitions des colonnes ») — centimes, devise de
/// la ligne. Un agent sans salaire ce mois dans cette devise a quand même sa
/// ligne s'il lui reste des arriérés : ce qui est dû ne disparaît pas du
/// tableau (comme `PayrollSituationReader.arrearsOnly` au serveur).
class PayrollDashboardRow {
  final String staffMemberId;
  final String currency;
  final int netInCents;

  /// Brut.
  final int plannedInCents;

  /// Absence + IPR + CNSS + PC/E + avances.
  final int deductionsInCents;

  /// Ce qui reste dû sur les paies validées des mois **antérieurs**, à ce
  /// jour.
  final int arrearsInCents;

  /// Versements vivants du mois sur la ligne ; 0 avant validation.
  final int receivedInCents;
  final PayrollDashboardStatus status;

  const PayrollDashboardRow({
    required this.staffMemberId,
    required this.currency,
    required this.netInCents,
    required this.plannedInCents,
    required this.deductionsInCents,
    required this.arrearsInCents,
    required this.receivedInCents,
    required this.status,
  });

  /// Net du mois + arriérés − perçu.
  int get remainingInCents {
    final remaining = netInCents + arrearsInCents - receivedInCents;
    return remaining < 0 ? 0 : remaining;
  }
}

/// Où en est le net d'un mois, pour une devise : payé, reporté par décision,
/// non payé — ou, avant validation, pas encore versé.
class PayrollNetProgress {
  final int paidInCents;
  final int deferredInCents;
  final int unpaidInCents;
  final int notYetInCents;
  final int settledCount;
  final int partialCount;
  final int unpaidCount;

  const PayrollNetProgress({
    this.paidInCents = 0,
    this.deferredInCents = 0,
    this.unpaidInCents = 0,
    this.notYetInCents = 0,
    this.settledCount = 0,
    this.partialCount = 0,
    this.unpaidCount = 0,
  });

  int get totalInCents =>
      paidInCents + deferredInCents + unpaidInCents + notYetInCents;
}

/// Prévu, retenues par nature et réel d'un mois, pour une devise.
class PayrollForecast {
  final int grossInCents;
  final int absenceInCents;
  final int advancesInCents;
  final int legalInCents;
  final int childcareInCents;
  final int netInCents;

  const PayrollForecast({
    this.grossInCents = 0,
    this.absenceInCents = 0,
    this.advancesInCents = 0,
    this.legalInCents = 0,
    this.childcareInCents = 0,
    this.netInCents = 0,
  });

  /// Ce que l'arrondi et un net plancher à zéro laissent hors des quatre
  /// natures : jamais négatif.
  int get otherInCents {
    final other =
        grossInCents -
        netInCents -
        absenceInCents -
        advancesInCents -
        legalInCents -
        childcareInCents;
    return other < 0 ? 0 : other;
  }

  int get savedInCents => grossInCents - netInCents;
}
