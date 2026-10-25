import 'package:school_app_flutter/features/payroll/domain/entities/payroll_fingerprint.dart';
import 'package:school_app_flutter/core/helpers/json_fields.dart';

/// L'empreinte d'un livre sur le fil (`expected` d'un geste, `server` d'un
/// refus `PAYROLL_STALE`) et dans la base (même forme, JSON).
abstract final class PayrollFingerprintJson {
  static Map<String, dynamic> encode(PayrollFingerprint fingerprint) => {
    'lineCount': fingerprint.lineCount,
    'totals': [
      for (final total in fingerprint.totals)
        {
          'currency': total.currency,
          'grossInCents': total.grossInCents,
          'deductionInCents': ?total.deductionInCents,
          'advanceInCents': total.advanceInCents,
          'netInCents': total.netInCents,
          'toPayInCents': ?total.toPayInCents,
        },
    ],
    'linesDigest': fingerprint.linesDigest,
    'formulaVersion': fingerprint.formulaVersion,
    if (fingerprint.lines.isNotEmpty)
      'lines': [
        for (final line in fingerprint.lines)
          {
            'staffMemberId': line.staffMemberId,
            'currency': line.currency,
            'grossInCents': line.grossInCents,
            'advanceInCents': line.advanceInCents,
            'netInCents': line.netInCents,
            if (line.formulaVersion >= 2) ...{
              'absenceInCents': line.absenceInCents,
              'iprInCents': line.iprInCents,
              'cnssInCents': line.cnssInCents,
              'childcareInCents': line.childcareInCents,
              'toPayInCents': line.toPayInCents,
            },
          },
      ],
  };

  static PayrollFingerprint? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final lineCount = raw.integer('lineCount');
    final totals = raw['totals'];
    if (lineCount == null || totals is! List) return null;
    final lines = raw['lines'];
    final version = raw.integer('formulaVersion') ?? 1;
    return PayrollFingerprint(
      lineCount: lineCount,
      formulaVersion: version,
      linesDigest: raw.text('linesDigest') ?? '',
      totals: [
        for (final item in totals)
          if (_total(item) case final PayrollTotal total) total,
      ],
      lines: [
        if (lines is List)
          for (final item in lines)
            if (_line(item, version) case final PayrollDigestLine line) line,
      ],
    );
  }

  static PayrollTotal? _total(Object? raw) {
    if (raw is! Map) return null;
    final currency = raw.text('currency');
    if (currency == null) return null;
    return PayrollTotal(
      currency: currency,
      grossInCents: raw.integer('grossInCents') ?? 0,
      advanceInCents: raw.integer('advanceInCents') ?? 0,
      netInCents: raw.integer('netInCents') ?? 0,
      deductionInCents: raw.integer('deductionInCents'),
      toPayInCents: raw.integer('toPayInCents'),
    );
  }

  static PayrollDigestLine? _line(Object? raw, int version) {
    if (raw is! Map) return null;
    final id = raw.text('staffMemberId');
    final currency = raw.text('currency');
    if (id == null || currency == null) return null;
    return PayrollDigestLine(
      staffMemberId: id.toLowerCase(),
      currency: currency,
      grossInCents: raw.integer('grossInCents') ?? 0,
      advanceInCents: raw.integer('advanceInCents') ?? 0,
      netInCents: raw.integer('netInCents') ?? 0,
      formulaVersion: version,
      absenceInCents: raw.integer('absenceInCents') ?? 0,
      iprInCents: raw.integer('iprInCents') ?? 0,
      cnssInCents: raw.integer('cnssInCents') ?? 0,
      childcareInCents: raw.integer('childcareInCents') ?? 0,
      toPayInCents: raw.integer('toPayInCents'),
    );
  }
}
