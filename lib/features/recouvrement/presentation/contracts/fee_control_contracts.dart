import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';

/// La **situation recherchée** — les cinq segments de l'écran.
///
/// Les quatre premiers sont des catégories et coïncident exactement avec
/// [StudentChargeStatus] : soldé = `paid`, partiel = `partial`, rien = `due`. On
/// ne redéclare donc pas un vocabulaire de statut ; seuls [all] et [threshold]
/// sont propres au filtre.
///
/// [threshold] n'est **pas** une catégorie : c'est un seuil, et il se saisit.
/// C'est aussi pourquoi aucune tuile de compteur ne l'active — un plancher ne se
/// devine pas.
enum FeeControlPaymentFilter { all, settled, partial, none, threshold }

extension FeeControlPaymentFilterX on FeeControlPaymentFilter {
  /// Statut visé, ou `null` quand le filtre ne se joue pas sur le statut
  /// ([all] et [threshold]).
  StudentChargeStatus? get targetStatus => switch (this) {
    FeeControlPaymentFilter.all => null,
    FeeControlPaymentFilter.settled => StudentChargeStatus.paid,
    FeeControlPaymentFilter.partial => StudentChargeStatus.partial,
    FeeControlPaymentFilter.none => StudentChargeStatus.due,
    FeeControlPaymentFilter.threshold => null,
  };

  /// Vrai pour le seul segment qui ouvre un champ de saisie.
  bool get needsThreshold => this == FeeControlPaymentFilter.threshold;
}

/// Une ligne de résultat : l'élève, et sa position sur **les frais retenus**.
///
/// Porte une [LocalRecoveryLine] — la même entité que le tableau de bord — et
/// non un agrégat mono-frais : c'est ce qui rend structurellement impossible que
/// les deux écrans du module se contredisent sur le même élève
/// (RECOUVREMENT_PLAN.md, invariant n° 1).
class FeeControlRow extends Equatable {
  final EnrollmentSummary summary;
  final LocalRecoveryLine line;

  const FeeControlRow({required this.summary, required this.line});

  String get studentId => line.studentId;

  /// Statut dérivé **des montants** (payé composé), jamais de la colonne
  /// `status` du grand-livre — celle-ci est un miroir serveur et ferait
  /// réapparaître « dû » un poste soldé hors-ligne.
  ///
  /// ⚠️ **Aucune tolérance d'arrondi.** La spec en pose une (« un centime
  /// résiduel ne fait pas un payeur », « reste ≤ ½ unité = soldé ») parce que sa
  /// maquette compte en flottants ; nous comptons en **centimes entiers**, où
  /// l'exactitude est atteignable. Et surtout : cette règle est celle de
  /// `LocalFeeChargeAggregate`, partagée avec le tableau de bord — la relâcher
  /// ici ferait diverger les deux écrans.
  StudentChargeStatus get status => line.status;

  MoneyBag get expected => line.expected;

  MoneyBag get paid => line.paidTotal;

  MoneyBag get remaining => line.remaining;

  /// Les devises que porte la ligne. Une seule dans le cas courant.
  Set<String> get currencies => {for (final c in line.charges) c.currency};

  /// Rien n'était attendu de cet élève : un taux n'aurait aucun sens.
  bool get hasNoExpectation =>
      line.charges.every((c) => c.expectedInCents <= 0);

  /// La position lue avec l'arithmétique **partagée avec le serveur** (payé
  /// imputable, reste planché par créance) — cf. [RecoveryStanding].
  RecoveryStanding get standing =>
      RecoveryStanding.of([for (final c in line.charges) c.position]);

  /// Taux d'avancement entier, mono-devise ; `null` en mixte — jamais de
  /// conversion (spec v2, R1).
  int? get progressPercent => standing.progressPercent;

  /// Le segment « a payé au moins… » applique **la règle AT_LEAST** du serveur
  /// (vecteurs partagés) : payé imputable ≥ seuil, ou plus rien à payer.
  bool matches(FeeControlPaymentFilter filter, {Money? threshold}) {
    if (filter == FeeControlPaymentFilter.threshold) {
      // Pas de plancher résolu (sélection mixte : la carte retombe sur
      // « Tous ») : rien n'est retenu contre l'élève. Un champ vide, lui, est
      // résolu en 0 (R3) en amont.
      if (threshold == null) return true;
      return standing.inOrder(RecoveryRuleKind.atLeast, threshold: threshold) ??
          false;
    }
    final target = filter.targetStatus;
    return target == null || status == target;
  }

  @override
  List<Object?> get props => [summary, line];
}

/// Une nature de frais de l'année et sa ou ses devise(s) — une ligne du choix
/// des frais (O1), groupé par devise.
class FeeNature extends Equatable {
  final String feeCode;

  /// Triées ; deux quand la nature est en dollars ici et en francs là.
  final List<String> currencies;

  const FeeNature({required this.feeCode, required this.currencies});

  @override
  List<Object?> get props => [feeCode, currencies];
}

/// Valeur de fil de la rubrique « Non affectés » — la même que le serveur
/// (`classroomId=UNASSIGNED`, périmètre `UNASSIGNED` de la liste de relance).
const String feeControlUnassigned = 'UNASSIGNED';

/// Critères posés par la carte de périmètre (sans l'année, que la page tient
/// du contexte académique).
class FeeControlSearchRequest extends Equatable {
  /// Une classe de l'année, ou [feeControlUnassigned] pour les élèves sans
  /// classe (spec v2, R2 ; arbitrage du 2026-11-22 : choix du champ Classe, en
  /// dernier).
  final String classroomId;

  /// Les natures de frais retenues, dans l'ordre de l'école. **Jamais vide**.
  final List<String> feeCodes;

  final FeeControlPaymentFilter statusFilter;

  /// Montant plancher du segment « A payé au moins… », **en centimes et sans
  /// devise** : la devise n'est connue qu'une fois la classe lue, et c'est le
  /// bloc qui la résout sur les lignes qu'il vient de lire (B1-B2). `null` hors
  /// de ce segment, ou champ vide (lu « 0 », spec R3).
  final int? thresholdInCents;

  const FeeControlSearchRequest({
    required this.classroomId,
    required this.feeCodes,
    required this.statusFilter,
    this.thresholdInCents,
  });

  bool get isUnassigned => classroomId == feeControlUnassigned;

  @override
  List<Object?> get props => [
    classroomId,
    feeCodes,
    statusFilter,
    thresholdInCents,
  ];
}

/// Photo immuable de la dernière recherche jouée — sert à la rejouer
/// (pagination, réessai) et à reconstituer la phrase qui rejoue la requête.
class FeeControlQuery extends Equatable {
  final String academicYearId;

  /// Une classe, ou [feeControlUnassigned].
  final String classroomId;

  final List<String> feeCodes;
  final FeeControlPaymentFilter statusFilter;

  /// Le montant saisi pour « a payé au moins… », en centimes, sans devise —
  /// ce que l'opérateur a voulu. `null` : champ vide (lu « 0 », spec R3).
  final int? thresholdInCents;

  /// Le plancher **résolu** sur la devise des lignes lues ([resolvedFor]) :
  /// c'est lui que le filtrage, la phrase et l'export appliquent. `null` hors
  /// du segment, en sélection mixte, ou tant que la classe n'est pas lue.
  final Money? threshold;

  final int page;
  final int size;

  const FeeControlQuery({
    required this.academicYearId,
    required this.classroomId,
    required this.feeCodes,
    required this.statusFilter,
    this.thresholdInCents,
    this.threshold,
    required this.page,
    required this.size,
  });

  bool get isUnassigned => classroomId == feeControlUnassigned;

  /// Le plancher de [filter] dans l'unique devise de [currencies] : champ
  /// vide = 0 (R3). `null` hors du segment, et en mixte ou sans ligne — la
  /// carte retombe alors sur « Tous ».
  static Money? thresholdFor(
    FeeControlPaymentFilter filter,
    int? thresholdInCents,
    Set<String> currencies,
  ) => filter.needsThreshold && currencies.length == 1
      ? Money.parse(thresholdInCents ?? 0, currencies.single)
      : null;

  /// La même question, son plancher résolu sur les devises de la classe lue.
  FeeControlQuery resolvedFor(Set<String> currencies) => _copy(
    threshold: thresholdFor(statusFilter, thresholdInCents, currencies),
  );

  /// La même question, posée sur une autre situation — ce que fait une tuile de
  /// compteur ou le champ du montant. Le plancher tombe hors de « a payé au
  /// moins… » ; il reste à résoudre ([resolvedFor]).
  FeeControlQuery copyWithSituation(
    FeeControlPaymentFilter filter, {
    int? thresholdInCents,
  }) => FeeControlQuery(
    academicYearId: academicYearId,
    classroomId: classroomId,
    feeCodes: feeCodes,
    statusFilter: filter,
    thresholdInCents: filter.needsThreshold ? thresholdInCents : null,
    page: 0,
    size: size,
  );

  FeeControlQuery copyWithPage(int page) => _copy(page: page);

  FeeControlQuery _copy({Object? threshold = _keepThreshold, int? page}) =>
      FeeControlQuery(
        academicYearId: academicYearId,
        classroomId: classroomId,
        feeCodes: feeCodes,
        statusFilter: statusFilter,
        thresholdInCents: thresholdInCents,
        threshold: identical(threshold, _keepThreshold)
            ? this.threshold
            : threshold as Money?,
        page: page ?? this.page,
        size: size,
      );

  @override
  List<Object?> get props => [
    academicYearId,
    classroomId,
    feeCodes,
    statusFilter,
    thresholdInCents,
    threshold,
    page,
    size,
  ];
}

const _keepThreshold = Object();

/// Ce que le tableau de bord transmet à l'écran nominatif quand on lui demande
/// « qui, précisément ? » (spec v2, R12 du contrôle) — et ce que l'adresse
/// retient (frais, classe, situation et son montant).
///
/// Repris **une seule fois**, à l'arrivée ; ensuite l'écran vit seul.
class FeeControlIntent extends Equatable {
  /// Une classe, [feeControlUnassigned], ou `null` : la classe de la dernière
  /// visite (périmètre « établissement » ou « cycle » côté tableau de bord).
  final String? classroomId;

  /// Les frais, dans l'ordre de l'école. Jamais vide.
  final List<String> feeCodes;

  final FeeControlPaymentFilter situation;

  /// Le montant du segment « a payé au moins… », en centimes.
  final int? thresholdInCents;

  const FeeControlIntent({
    this.classroomId,
    required this.feeCodes,
    this.situation = FeeControlPaymentFilter.all,
    this.thresholdInCents,
  });

  /// Les clés que l'écran tient dans l'adresse — et efface quand elles
  /// tombent.
  static const queryKeys = [
    _feesKey,
    _classroomKey,
    _situationKey,
    _thresholdKey,
  ];

  static const _classroomKey = 'classe';
  static const _feesKey = 'frais';
  static const _situationKey = 'situation';
  static const _thresholdKey = 'montant';

  static const _situationWire = {
    FeeControlPaymentFilter.all: 'tous',
    FeeControlPaymentFilter.none: 'rien',
    FeeControlPaymentFilter.partial: 'partiel',
    FeeControlPaymentFilter.settled: 'solde',
    FeeControlPaymentFilter.threshold: 'au-moins',
  };

  /// La question écrite dans l'adresse : un onglet rechargé ou un lien collé
  /// rouvre la même liste (spec v2, §0 « Ce que l'adresse retient »).
  Map<String, String> toQueryParameters() => {
    _feesKey: feeCodes.join(','),
    _classroomKey: ?classroomId,
    if (situation != FeeControlPaymentFilter.all)
      _situationKey: _situationWire[situation]!,
    if (situation.needsThreshold && thresholdInCents != null)
      _thresholdKey: '$thresholdInCents',
  };

  /// Reconstruit l'intention depuis la route : `extra` d'abord, l'adresse
  /// ensuite. `null` sans frais : l'écran s'ouvre alors sur la dernière visite.
  static FeeControlIntent? fromRoute(
    Object? extra, [
    Map<String, String> queryParameters = const {},
  ]) {
    if (extra is FeeControlIntent) return extra;
    String? read(String key) {
      final value = queryParameters[key]?.trim() ?? '';
      return value.isEmpty ? null : value;
    }

    final fees = [
      for (final code in (read(_feesKey) ?? '').split(','))
        if (code.trim().isNotEmpty) code.trim(),
    ];
    if (fees.isEmpty) return null;
    final wire = read(_situationKey);
    final situation = _situationWire.entries
        .where((e) => e.value == wire)
        .map((e) => e.key)
        .firstOrNull;
    final amount = int.tryParse(read(_thresholdKey) ?? '');
    return FeeControlIntent(
      classroomId: read(_classroomKey),
      feeCodes: fees,
      situation: situation ?? FeeControlPaymentFilter.all,
      thresholdInCents: amount != null && amount >= 0 ? amount : null,
    );
  }

  @override
  List<Object?> get props => [
    classroomId,
    feeCodes,
    situation,
    thresholdInCents,
  ];
}
