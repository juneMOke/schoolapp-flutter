import 'package:school_app_flutter/features/treasury/domain/entities/report_signatory.dart';

/// Les signataires des rapports sur le fil (`/treasury/report-signatories`).
abstract final class ReportSignatoriesWire {
  static ReportSignatories fromJson(Object? body) {
    if (body is! Map) {
      throw const FormatException('Signataires illisibles');
    }
    final json = Map<String, dynamic>.from(body);
    final updatedAt = json['updatedAt'] as String?;
    return ReportSignatories(
      signatories: _list(json['signatories']),
      defaults: json['defaults'] == true,
      defaultSignatories: _list(json['defaultSignatories']),
      // Gardé tel que reçu : la microseconde doit revenir intacte.
      updatedAtWire: updatedAt,
      updatedAt: updatedAt == null ? null : DateTime.tryParse(updatedAt),
      updatedByName: json['updatedByName'] as String?,
    );
  }

  /// Les signataires portés par un `409 SIGNATORIES_CHANGED` ; illisibles ⇒
  /// `null`, le refus reste lisible sans eux.
  static ReportSignatories? fromDetails(Map<String, dynamic> details) {
    if (details['signatories'] == null) return null;
    try {
      return fromJson(details);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> putBody({
    required String? expectedUpdatedAt,
    required List<ReportSignatory> signatories,
  }) => {
    'expectedUpdatedAt': expectedUpdatedAt,
    'signatories': [
      for (final s in signatories)
        {
          'rank': s.rank,
          'caption': s.caption,
          'name': s.name,
          'function': s.function,
          'filledByCloser': s.filledByCloser,
        },
    ],
  };

  static List<ReportSignatory> _list(Object? raw) => [
    for (final entry in (raw as List?) ?? const [])
      _signatory(Map<String, dynamic>.from(entry as Map)),
  ]..sort((a, b) => a.rank.compareTo(b.rank));

  static ReportSignatory _signatory(Map<String, dynamic> json) {
    final rank = json['rank'];
    final caption = json['caption'];
    final function = json['function'];
    if (rank is! num || caption is! String || function is! String) {
      throw const FormatException('Signataire illisible');
    }
    return ReportSignatory(
      rank: rank.toInt(),
      caption: caption,
      name: json['name'] as String?,
      function: function,
      filledByCloser: json['filledByCloser'] == true,
    );
  }
}
