import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';

/// Les vecteurs **partagés avec le back** (copie conforme de
/// `eteelo-backend/src/test/resources/finance/recovery-status-vectors.json`).
/// Un écart ici, c'est le tableau de bord (serveur) et le contrôle (tablette)
/// qui se contredisent sur le même élève.
void main() {
  final json =
      jsonDecode(
            File(
              'test/fixtures/recouvrement/recovery-status-vectors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  List<FeeChargePosition> positions(List<dynamic> charges) => [
    for (final c in charges.cast<Map<String, dynamic>>())
      FeeChargePosition(
        currency: c['currency'] as String,
        expectedInCents: c['expectedInCents'] as int,
        paidMirrorInCents: c['paidInCents'] as int,
        paidPendingInCents: 0,
      ),
  ];

  Map<String, int> asMap(MoneyBag bag) => {
    for (final m in bag.entries) m.currency: m.amountInCents,
  };

  const situations = {
    'NO_PAYMENT': StudentChargeStatus.due,
    'PARTIAL': StudentChargeStatus.partial,
    'SETTLED': StudentChargeStatus.paid,
  };

  group('statut et règles', () {
    for (final c in (json['cases'] as List).cast<Map<String, dynamic>>()) {
      test(c['name'] as String, () {
        final s = RecoveryStanding.of(positions(c['charges'] as List));
        expect(asMap(s.due), c['due']);
        expect(asMap(s.paid), c['paid']);
        expect(asMap(s.outstanding), c['outstanding']);
        expect(asMap(s.imputable), c['imputable']);
        expect(s.situation, situations[c['situation']]);
        final inOrder = c['inOrder'] as Map<String, dynamic>;
        expect(
          s.inOrder(RecoveryRuleKind.somePayment),
          inOrder['SOME_PAYMENT'],
        );
        expect(
          s.inOrder(RecoveryRuleKind.fullySettled),
          inOrder['FULLY_SETTLED'],
        );
        final atLeast = c['atLeast'] as List?;
        if (atLeast == null) {
          // Mixte : la question n'existe pas, même avec un montant.
          expect(
            s.inOrder(
              RecoveryRuleKind.atLeast,
              threshold: Money.parse(100, 'USD'),
            ),
            isNull,
          );
        } else {
          for (final a in atLeast.cast<Map<String, dynamic>>()) {
            expect(
              s.inOrder(
                RecoveryRuleKind.atLeast,
                threshold: Money.parse(
                  a['thresholdInCents'] as int,
                  a['currency'] as String,
                ),
              ),
              a['inOrder'],
              reason: 'seuil ${a['thresholdInCents']}',
            );
          }
        }
      });
    }
  });

  group('tri', () {
    for (final c in (json['sorting'] as List).cast<Map<String, dynamic>>()) {
      test(c['name'] as String, () {
        final students = (c['students'] as List).cast<Map<String, dynamic>>();
        final rows = [
          for (final s in students)
            (
              id: s['studentId'] as String,
              name: s['displayName'] as String,
              standing: RecoveryStanding.of(positions(s['charges'] as List)),
            ),
        ];
        final mixed = rows.any((r) => r.standing.isMultiCurrency);
        rows.sort((a, b) {
          final byStanding = RecoveryStanding.compareStanding(
            a.standing,
            b.standing,
            mixed: mixed,
          );
          if (byStanding != 0) return byStanding;
          final byName = _fold(a.name).compareTo(_fold(b.name));
          return byName != 0 ? byName : a.id.compareTo(b.id);
        });
        expect([for (final r in rows) r.id], c['expectedOrder']);
      });
    }
  });
}

/// Collation française au premier niveau : accents et casse ignorés.
String _fold(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[àâä]'), 'a')
    .replaceAll(RegExp('[îï]'), 'i')
    .replaceAll(RegExp('[ôö]'), 'o')
    .replaceAll(RegExp('[ùûü]'), 'u')
    .replaceAll('ç', 'c');
