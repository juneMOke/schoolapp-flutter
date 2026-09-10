import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_pivot.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_rate.dart';

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

  /// Taux de recouvrement de la ligne, en pourcentage entier — l'ordre de
  /// travail de l'écran.
  ///
  /// `null` quand la ligne mêle deux devises et qu'aucun cours ne les rapproche.
  /// C'est « on ne sait pas », jamais zéro : un élève à jour n'a pas à remonter
  /// en tête d'une liste de relance parce que le taux du jour manque.
  ///
  /// La règle est `(attendu − reste) / attendu`, celle de [RecoveryRate], et
  /// non `payé / attendu` comme la spec l'écrit : la seconde franchit 100 % dès
  /// qu'un versement solde la créance d'un autre exercice, et le serveur comme
  /// le tableau de bord appliquent déjà la première.
  int? ratePercent(ExchangeRate? rate) {
    final pivot = currencies.length == 1 ? currencies.first : CurrencyCode.usd;
    final expectedPivot = RecouvrementPivot.inCurrency(expected, pivot, rate);
    final remainingPivot = RecouvrementPivot.inCurrency(remaining, pivot, rate);
    if (expectedPivot == null || remainingPivot == null) return null;
    return RecoveryRate.of(
      expectedInCents: expectedPivot,
      remainingInCents: remainingPivot,
    );
  }

  /// A payé **au moins** [threshold], tout ramené dans la devise du plancher.
  ///
  /// `false` quand une devise ne s'y convertit pas : on n'affirme pas qu'un
  /// élève a fait un geste sur un chiffre inventé.
  bool paidAtLeast(Money threshold, ExchangeRate? rate) {
    final paidPivot = RecouvrementPivot.inCurrency(
      paid,
      threshold.currency,
      rate,
    );
    if (paidPivot == null) return false;
    return paidPivot >= threshold.amountInCents;
  }

  bool matches(
    FeeControlPaymentFilter filter, {
    Money? threshold,
    ExchangeRate? rate,
  }) {
    if (filter == FeeControlPaymentFilter.threshold) {
      // Un plancher vide vise tout le monde : « a payé au moins zéro » est vrai
      // de chacun, et c'est la lecture littérale d'un champ qu'on n'a pas encore
      // rempli.
      return threshold == null || paidAtLeast(threshold, rate);
    }
    final target = filter.targetStatus;
    return target == null || status == target;
  }

  @override
  List<Object?> get props => [summary, line];
}

/// Critères posés par le formulaire (sans l'année, que la page tient du
/// contexte académique).
class FeeControlSearchRequest extends Equatable {
  final String schoolLevelGroupId;
  final String schoolLevelId;

  /// Classe visée, ou `null` pour « toutes les classes du niveau ». Facultatif :
  /// un niveau dont les classes ne sont pas encore composées doit rester
  /// contrôlable.
  final String? classroomId;

  /// Les natures de frais retenues. **Jamais vide** — le sélecteur ignore le
  /// clic qui décocherait la dernière.
  final List<String> feeCodes;

  final FeeControlPaymentFilter statusFilter;

  /// Montant plancher du segment « A payé au moins… ». `null` hors de ce
  /// segment, et `null` aussi quand la sélection mêle deux devises : comparer
  /// 50 000 FC à 120 $ n'a pas de sens, et l'écran refuse de le simuler.
  final Money? threshold;

  const FeeControlSearchRequest({
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    this.classroomId,
    required this.feeCodes,
    required this.statusFilter,
    this.threshold,
  });

  @override
  List<Object?> get props => [
    schoolLevelGroupId,
    schoolLevelId,
    classroomId,
    feeCodes,
    statusFilter,
    threshold,
  ];
}

/// Photo immuable de la dernière recherche jouée — sert à la rejouer
/// (pagination, réessai) et à reconstituer la phrase qui rejoue la requête.
class FeeControlQuery extends Equatable {
  final String academicYearId;
  final String schoolLevelGroupId;
  final String schoolLevelId;

  /// Classe visée, ou `null` pour tout le niveau.
  final String? classroomId;

  final List<String> feeCodes;
  final FeeControlPaymentFilter statusFilter;
  final Money? threshold;

  /// Cours du jour au moment de la lecture. **Transporté dans la requête** et
  /// non lu au vol : le réessai et la pagination doivent rejouer le même
  /// classement, et un taux qui bouge entre deux pages réordonnerait la liste
  /// sous les doigts.
  final ExchangeRate? rate;

  final int page;
  final int size;

  const FeeControlQuery({
    required this.academicYearId,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    this.classroomId,
    required this.feeCodes,
    required this.statusFilter,
    this.threshold,
    this.rate,
    required this.page,
    required this.size,
  });

  /// La même question, posée sur une autre situation — ce que fait une tuile de
  /// compteur.
  ///
  /// Le plancher tombe : aucune tuile n'active « a payé au moins… », et le
  /// garder ferait filtrer sur un seuil que plus rien n'affiche.
  FeeControlQuery copyWithSituation(FeeControlPaymentFilter filter) =>
      FeeControlQuery(
        academicYearId: academicYearId,
        schoolLevelGroupId: schoolLevelGroupId,
        schoolLevelId: schoolLevelId,
        classroomId: classroomId,
        feeCodes: feeCodes,
        statusFilter: filter,
        rate: rate,
        page: 0,
        size: size,
      );

  FeeControlQuery copyWithPage(int page) => FeeControlQuery(
    academicYearId: academicYearId,
    schoolLevelGroupId: schoolLevelGroupId,
    schoolLevelId: schoolLevelId,
    classroomId: classroomId,
    feeCodes: feeCodes,
    statusFilter: statusFilter,
    threshold: threshold,
    rate: rate,
    page: page,
    size: size,
  );

  @override
  List<Object?> get props => [
    academicYearId,
    schoolLevelGroupId,
    schoolLevelId,
    classroomId,
    feeCodes,
    statusFilter,
    threshold,
    rate,
    page,
    size,
  ];
}

/// Ce que le tableau de bord transmet à l'écran nominatif quand on lui demande
/// « qui, précisément ? ».
///
/// Le tableau de bord pose la question, l'écran voisin donne les noms : le
/// passage doit conserver **exactement** le périmètre lu, sinon la liste ne
/// répondrait pas de la synthèse qui l'a ouverte.
class FeeControlIntent extends Equatable {
  final String schoolLevelGroupId;
  final String schoolLevelId;

  /// Classe visée, `null` pour tout le niveau — selon qu'on parte d'une ligne
  /// de classe ou de la ligne du niveau.
  final String? classroomId;

  final String feeCode;

  const FeeControlIntent({
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    this.classroomId,
    required this.feeCode,
  });

  /// Reconstruit l'intention depuis `extra` de la route. `null` dès qu'il n'y a
  /// rien à reconstruire : l'écran s'ouvre alors vierge, comme par le menu.
  static FeeControlIntent? fromRouteExtra(Object? extra) =>
      extra is FeeControlIntent ? extra : null;

  @override
  List<Object?> get props => [
    schoolLevelGroupId,
    schoolLevelId,
    classroomId,
    feeCode,
  ];
}
