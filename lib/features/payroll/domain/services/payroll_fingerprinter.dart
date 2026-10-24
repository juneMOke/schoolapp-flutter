import 'dart:convert';

import 'package:school_app_flutter/core/crypto/sha256_hex.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_fingerprint.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';

/// L'empreinte d'un livre : ce que la direction a vu, sous la forme exacte que
/// le serveur recalcule (Q2).
///
/// `linesDigest` = SHA-256 hexadécimal de la forme canonique de chaque ligne
/// ([PayrollDigestLine.canonical], v1 ou v2 selon [formulaVersion]), une
/// ligne par agent triée par `staffMemberId`, jointes par `\n` sans `\n`
/// final ; livre vide = empreinte de la chaîne vide.
///
/// Tout calcul de la tablette est v2 ([PayrollLine.currentFormula]) ; la v1
/// ne sert qu'à relire les vecteurs et les paies figées avant la v2.
abstract final class PayrollFingerprinter {
  static Future<PayrollFingerprint> of(
    List<PayrollLine> lines, {
    int formulaVersion = PayrollLine.currentFormula,
  }) async {
    final reduced = digestLines(lines, formulaVersion: formulaVersion);
    return PayrollFingerprint(
      lineCount: reduced.length,
      totals: totalsOf(reduced),
      linesDigest: await digestOf(reduced),
      formulaVersion: formulaVersion,
    );
  }

  static List<PayrollDigestLine> digestLines(
    List<PayrollLine> lines, {
    int formulaVersion = PayrollLine.currentFormula,
  }) => [
    for (final line in lines)
      PayrollDigestLine(
        staffMemberId: line.staffMemberId.toLowerCase(),
        currency: line.currency,
        grossInCents: line.grossInCents,
        advanceInCents: line.advanceInCents,
        netInCents: line.netInCents,
        formulaVersion: formulaVersion,
        fixedDeductionsInCents: line.deductions.totalInCents,
        toPayInCents: line.toPayInCents,
      ),
  ]..sort((a, b) => a.staffMemberId.compareTo(b.staffMemberId));

  static Future<String> digestOf(List<PayrollDigestLine> sorted) =>
      sha256Hex(utf8.encode(sorted.map((line) => line.canonical).join('\n')));

  /// Les totaux par devise, triés par code.
  static List<PayrollTotal> totalsOf(Iterable<PayrollDigestLine> lines) {
    final byCurrency = <String, List<int>>{};
    for (final line in lines) {
      final sums = byCurrency.putIfAbsent(line.currency, () => [0, 0, 0]);
      sums[0] += line.grossInCents;
      sums[1] += line.advanceInCents;
      sums[2] += line.netInCents;
    }
    final currencies = byCurrency.keys.toList()..sort();
    return [
      for (final currency in currencies)
        PayrollTotal(
          currency: currency,
          grossInCents: byCurrency[currency]![0],
          advanceInCents: byCurrency[currency]![1],
          netInCents: byCurrency[currency]![2],
        ),
    ];
  }

  /// Les agents dont la ligne diffère entre ce qui a été vu et ce que le
  /// serveur a calculé — lus par l'écran de confrontation.
  static Set<String> differingMembers(
    List<PayrollDigestLine> seen,
    List<PayrollDigestLine> server,
  ) {
    final bySeen = {for (final line in seen) line.staffMemberId: line};
    final byServer = {for (final line in server) line.staffMemberId: line};
    return {
      for (final id in {...bySeen.keys, ...byServer.keys})
        if (bySeen[id] != byServer[id]) id,
    };
  }
}
