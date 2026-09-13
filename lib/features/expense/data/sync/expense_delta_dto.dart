import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_day.dart';

/// L'état canonique d'une dépense (`ExpenseDelta`) — la même forme dans le
/// flux de descente et dans l'accusé d'une remontée.
///
/// **Lu sans lever** ([tryParse]) : une ligne serveur malformée est écartée
/// et le curseur avance — elle ne redescendra qu'à sa prochaine modification
/// côté serveur, ou à une remise à zéro du curseur. C'est le moindre mal : un
/// cast strict ferait tomber la page entière, le curseur ne bougerait plus, et
/// le registre se figerait en silence (« poison-page »).
class ExpenseDeltaDto {
  final String id;
  final String? expenseNumber;
  final String typeId;
  final String title;
  final String? description;
  final int amountInCents;
  final String currency;
  final String status;

  /// `YYYY-MM-DD`.
  final String? paidOn;
  final String expenseDate;
  final String? supplier;
  final String fundingSource;
  final String? recordedById;
  final String? recordedByName;

  /// ISO-8601 UTC, normalisé.
  final String clientUpdatedAt;
  final String? deletedAt;
  final int? version;
  final String? serverUpdatedAt;

  const ExpenseDeltaDto({
    required this.id,
    this.expenseNumber,
    required this.typeId,
    required this.title,
    this.description,
    required this.amountInCents,
    required this.currency,
    required this.status,
    this.paidOn,
    required this.expenseDate,
    this.supplier,
    this.fundingSource = 'CASH',
    this.recordedById,
    this.recordedByName,
    required this.clientUpdatedAt,
    this.deletedAt,
    this.version,
    this.serverUpdatedAt,
  });

  static ExpenseDeltaDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    String? text(String key) {
      final value = raw[key];
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    String? instant(String key) =>
        DateTime.tryParse(text(key) ?? '')?.toUtc().toIso8601String();

    final id = text('id');
    final typeId = text('typeId');
    final title = text('title');
    final amount = raw['amountInCents'];
    // Devise normalisée, jamais rejetée : une devise ajoutée un jour au
    // serveur ne doit pas rendre sa dépense invisible.
    final currency = text('currency')?.toUpperCase();
    final status = text('status')?.toUpperCase();
    final expenseDate = ExpenseDay.tryParse(text('expenseDate'));
    final clientUpdatedAt = instant('clientUpdatedAt');
    if (id == null ||
        typeId == null ||
        title == null ||
        amount is! num ||
        currency == null ||
        status == null ||
        expenseDate == null ||
        clientUpdatedAt == null) {
      return null;
    }
    final paidOn = ExpenseDay.tryParse(text('paidOn'));
    final version = raw['version'];
    return ExpenseDeltaDto(
      id: id,
      expenseNumber: text('expenseNumber'),
      typeId: typeId,
      title: title,
      description: text('description'),
      amountInCents: amount.toInt(),
      currency: currency,
      status: status,
      paidOn: paidOn == null ? null : ExpenseDay.format(paidOn),
      expenseDate: ExpenseDay.format(expenseDate),
      supplier: text('supplier'),
      fundingSource: text('fundingSource')?.toUpperCase() ?? 'CASH',
      recordedById: text('recordedById'),
      recordedByName: text('recordedByName'),
      clientUpdatedAt: clientUpdatedAt,
      deletedAt: instant('deletedAt'),
      version: version is num ? version.toInt() : null,
      serverUpdatedAt: text('serverUpdatedAt'),
    );
  }
}

/// Page keyset du registre (`ExpensePage`).
class ExpensePageDto implements KeysetPageDto<ExpenseDeltaDto> {
  @override
  final List<ExpenseDeltaDto> items;
  @override
  final KeysetPageEnvelope page;

  /// Lignes écartées à la lecture — mesurées pour qu'un test puisse prouver
  /// qu'une ligne fautive n'emporte pas les autres.
  final int skipped;

  const ExpensePageDto({
    required this.items,
    required this.page,
    this.skipped = 0,
  });

  factory ExpensePageDto.fromJson(Map<String, dynamic> j) {
    final raw = j['items'];
    final items = <ExpenseDeltaDto>[];
    var skipped = 0;
    if (raw is List) {
      for (final item in raw) {
        final parsed = ExpenseDeltaDto.tryParse(item);
        if (parsed == null) {
          skipped++;
        } else {
          items.add(parsed);
        }
      }
    }
    return ExpensePageDto(
      items: items,
      page: KeysetPageEnvelope.fromJson(j),
      skipped: skipped,
    );
  }
}
