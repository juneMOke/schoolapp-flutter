import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';

/// Les trois règles « est en ordre l'élève qui… » du Recouvrement v2.
///
/// Mêmes noms de fil que le serveur (`rule=SOME_PAYMENT|FULLY_SETTLED|
/// AT_LEAST`) : le tableau de bord les envoie telles quelles.
enum RecoveryRuleKind {
  /// A payé quelque chose — le défaut.
  somePayment('SOME_PAYMENT'),

  /// A tout soldé.
  fullySettled('FULLY_SETTLED'),

  /// A payé au moins un montant, dans l'unique devise du périmètre.
  atLeast('AT_LEAST');

  final String wire;

  const RecoveryRuleKind(this.wire);
}

/// La position d'un élève sur une sélection de frais, telle que le Recouvrement
/// v2 la lit — **la même arithmétique que le serveur**, vérifiée contre
/// `test/fixtures/recouvrement/recovery-status-vectors.json`, copie conforme du
/// fichier de vecteurs du back.
///
/// Par créance : reste = max(0, dû − payé). Par devise : dû et payé brut
/// sommés, reste = somme des restes planchés **créance par créance**, imputable
/// = dû − reste = Σ min(dû, payé). Un trop-perçu sur un frais ne couvre donc
/// jamais l'impayé d'un autre.
class RecoveryStanding extends Equatable {
  final MoneyBag due;

  /// Payé **brut**, jamais plafonné : c'est ce que la colonne « Payé » écrit.
  final MoneyBag paid;
  final MoneyBag outstanding;

  /// Payé **imputable** : ce que « a payé au moins » compare.
  final MoneyBag imputable;

  const RecoveryStanding._({
    required this.due,
    required this.paid,
    required this.outstanding,
    required this.imputable,
  });

  factory RecoveryStanding.of(Iterable<FeeChargePosition> positions) {
    final due = <String, int>{};
    final paid = <String, int>{};
    final outstanding = <String, int>{};
    for (final p in positions) {
      due.update(
        p.currency,
        (v) => v + p.expectedInCents,
        ifAbsent: () => p.expectedInCents,
      );
      paid.update(
        p.currency,
        (v) => v + p.paidTotalInCents,
        ifAbsent: () => p.paidTotalInCents,
      );
      outstanding.update(
        p.currency,
        (v) => v + p.remainingInCents,
        ifAbsent: () => p.remainingInCents,
      );
    }
    MoneyBag bag(Map<String, int> m) =>
        MoneyBag.sumBy(m.entries, (e) => Money.parse(e.value, e.key));
    return RecoveryStanding._(
      due: bag(due),
      paid: bag(paid),
      outstanding: bag(outstanding),
      imputable: bag({
        for (final c in due.keys) c: due[c]! - (outstanding[c] ?? 0),
      }),
    );
  }

  /// Testée dans cet ordre : SOLDÉ si plus rien ne reste dans aucune devise —
  /// un élève dont tous les dus valent 0 (exonéré) est donc soldé —, sinon
  /// RIEN PAYÉ si le payé brut est nul partout, sinon PARTIEL.
  StudentChargeStatus get situation {
    if (outstanding.entries.every((m) => m.amountInCents <= 0)) {
      return StudentChargeStatus.paid;
    }
    if (paid.entries.every((m) => m.amountInCents <= 0)) {
      return StudentChargeStatus.due;
    }
    return StudentChargeStatus.partial;
  }

  bool get isMultiCurrency => due.isMultiCurrency;

  /// En ordre selon [rule] ; [threshold] n'est lu que pour
  /// [RecoveryRuleKind.atLeast].
  ///
  /// `null` quand la question n'a pas de réponse honnête : « au moins » sans
  /// montant, ou dans une autre devise que celle(s) de l'élève. Jamais de
  /// conversion.
  bool? inOrder(RecoveryRuleKind rule, {Money? threshold}) {
    final s = situation;
    switch (rule) {
      case RecoveryRuleKind.somePayment:
        return s != StudentChargeStatus.due;
      case RecoveryRuleKind.fullySettled:
        return s == StudentChargeStatus.paid;
      case RecoveryRuleKind.atLeast:
        if (threshold == null || isMultiCurrency) return null;
        // Soldé (exonéré compris) : il ne doit plus rien, il est en ordre même
        // si son dû est sous le seuil (arbitrage du 2026-11-22, vecteur
        // « solde mais du sous le seuil »).
        if (s == StudentChargeStatus.paid) return true;
        final mine = imputable.amountIn(threshold.currency);
        if (mine == null) return null;
        return mine.amountInCents >= threshold.amountInCents;
    }
  }

  /// Avancement comparé **en produits croisés d'entiers** (imputable / dû, 1
  /// quand le dû est nul) — mono-devise seulement. Négatif si [this] est moins
  /// avancé que [other].
  int compareProgress(RecoveryStanding other) {
    final a = due.soleEntry;
    final b = other.due.soleEntry;
    final ai = a == null
        ? 0
        : imputable.amountIn(a.currency)?.amountInCents ?? 0;
    final bi = b == null
        ? 0
        : other.imputable.amountIn(b.currency)?.amountInCents ?? 0;
    final ad = a?.amountInCents ?? 0;
    final bd = b?.amountInCents ?? 0;
    // a = ai/ad, b = bi/bd ; dû nul ⇒ avancement 1 (soit 1/1).
    final an = ad == 0 ? 1 : ai;
    final aden = ad == 0 ? 1 : ad;
    final bn = bd == 0 ? 1 : bi;
    final bden = bd == 0 ? 1 : bd;
    return (an * bden).compareTo(bn * aden);
  }

  /// Rang de situation pour le tri mixte : rien payé, partiel, soldé.
  int get situationRank => switch (situation) {
    StudentChargeStatus.due => 0,
    StudentChargeStatus.partial => 1,
    StudentChargeStatus.paid => 2,
  };

  /// L'ordre « du moins avancé au plus avancé », **sans** le départage par
  /// nom : avancement en mono-devise, situation en mixte. [mixed] dit si le
  /// PÉRIMÈTRE porte deux devises (et non la seule ligne).
  static int compareStanding(
    RecoveryStanding a,
    RecoveryStanding b, {
    required bool mixed,
  }) =>
      mixed ? a.situationRank.compareTo(b.situationRank) : a.compareProgress(b);

  /// Taux d'avancement entier, mono-devise ; `null` en mixte ou sans dû.
  /// Même arrondi que `RecoveryRate.of` : (dû − reste) × 100 / dû, arrondi.
  int? get progressPercent {
    final d = due.soleEntry;
    if (d == null || d.amountInCents <= 0) return null;
    final i = imputable.amountIn(d.currency)?.amountInCents ?? 0;
    return (i * 100 / d.amountInCents).round().clamp(0, 100);
  }

  @override
  List<Object?> get props => [due, paid, outstanding, imputable];
}
