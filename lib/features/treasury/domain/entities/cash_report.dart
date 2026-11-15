import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';

/// Les rapports de caisse (A5). `period` ne se liste pas : la tablette garde
/// les siens pendant la session (D31).
enum CashReportKind {
  daily('DAILY'),
  weekly('WEEKLY'),
  monthly('MONTHLY'),
  yearly('YEARLY'),
  period('PERIOD');

  const CashReportKind(this.wire);

  final String wire;

  static CashReportKind? fromWire(String? value) {
    for (final kind in values) {
      if (kind.wire == value) return kind;
    }
    return null;
  }
}

/// R8, au moment de l'appel : définitif une fois la journée (ou toutes les
/// journées d'une période terminée) clôturée.
enum CashReportStatus {
  finalReport('FINAL'),
  provisional('PROVISIONAL');

  const CashReportStatus(this.wire);

  final String wire;

  static CashReportStatus? fromWire(String? value) {
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}

enum CashReportFormat { pdf, xlsx }

/// Un rapport : rien n'est stocké côté serveur, son id encode son type et sa
/// plage (`RJ-20261022`, `RH-20261019-1024`…) et sert aussi de nom de fichier
/// et de référence imprimée.
class CashReport extends Equatable {
  final String id;
  final CashReportKind kind;
  final DateTime from;

  /// La fin titrée (samedi, dernier jour du mois), même en cours.
  final DateTime to;

  /// En français, tel qu'imprimé : « Jeudi 22 octobre 2026 ».
  final String title;
  final CashReportStatus status;

  /// La plage contient aujourd'hui (« jusqu'à aujourd'hui »).
  final bool inProgress;
  final List<TreasuryCurrency> currencies;

  /// Archivé (V212) : définitif, dernière journée passée, contenu figé — ses
  /// signataires ne changent plus et son PDF porte un QR de vérification.
  final bool archived;
  final DateTime? archivedAt;

  const CashReport({
    required this.id,
    required this.kind,
    required this.from,
    required this.to,
    required this.title,
    required this.status,
    required this.inProgress,
    required this.currencies,
    this.archived = false,
    this.archivedAt,
  });

  bool get isFinal => status == CashReportStatus.finalReport;

  @override
  List<Object?> get props => [
    id,
    kind,
    from,
    to,
    title,
    status,
    inProgress,
    currencies,
    archived,
    archivedAt,
  ];
}

/// Une page de la liste, la plus récente en tête.
class CashReportPage extends Equatable {
  final List<CashReport> items;
  final int number;
  final int totalPages;

  const CashReportPage({
    required this.items,
    required this.number,
    required this.totalPages,
  });

  @override
  List<Object?> get props => [items, number, totalPages];
}

/// Le fichier d'un rapport, généré à chaque appel.
class CashReportFile extends Equatable {
  final Uint8List bytes;
  final String fileName;
  final CashReportFormat format;

  /// `X-Report-Status` : le filigrane est déjà dans le fichier, l'écran dit
  /// seulement que c'est provisoire.
  final CashReportStatus? status;

  const CashReportFile({
    required this.bytes,
    required this.fileName,
    required this.format,
    this.status,
  });

  @override
  List<Object?> get props => [bytes, fileName, format, status];
}

/// Les ids recalculables du contrat, pour ouvrir un rapport depuis l'écran de
/// clôture sans passer par la liste (R7). Une semaine coupée par le mois passe
/// par `POST /reports` : elle n'a pas d'id calculable ici.
abstract final class CashReportIds {
  static String daily(DateTime day) => 'RJ-${_ymd(day)}';

  /// Fin à 4 chiffres dans l'année du début ; en entier (`yyyyMMdd`) quand
  /// elle tombe l'année suivante — règle commune à RH, RM et RP, confirmée par
  /// le back (#229). Une seule forme par rapport : une fin longue dans l'année
  /// du début répondrait `400 INVALID_REPORT_ID`.
  static String weekly(DateTime monday, DateTime saturday) =>
      'RH-${_ymd(monday)}-${_end(monday, saturday)}';

  static String monthly(DateTime first, DateTime last) =>
      'RM-${_ymd(first)}-${_end(first, last)}';

  static String _end(DateTime from, DateTime to) =>
      to.year == from.year ? _md(to) : _ymd(to);

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${_md(d)}';

  static String _md(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
}
