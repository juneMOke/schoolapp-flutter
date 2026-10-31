import 'package:school_app_flutter/core/helpers/json_fields.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';

/// Une saisie de rubrique telle qu'elle descend avec la paie (`deductions[]`).
class PayrollDeductionDto {
  final String staffMemberId;
  final String deductionTypeId;
  final int amountInCents;
  final String currency;
  final String clientUpdatedAt;

  const PayrollDeductionDto({
    required this.staffMemberId,
    required this.deductionTypeId,
    required this.amountInCents,
    required this.currency,
    required this.clientUpdatedAt,
  });

  static PayrollDeductionDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final member = raw.text('staffMemberId');
    final type = raw.text('deductionTypeId');
    final amount = raw.integer('amountInCents');
    final currency = raw.text('currency');
    final at = raw.instant('clientUpdatedAt');
    if (member == null ||
        type == null ||
        amount == null ||
        currency == null ||
        at == null) {
      return null;
    }
    return PayrollDeductionDto(
      staffMemberId: member,
      deductionTypeId: type.toLowerCase(),
      amountInCents: amount,
      currency: currency,
      clientUpdatedAt: at,
    );
  }

  /// `deductions[]` d'une paie. `null` si le champ manque ou si une saisie est
  /// illisible : la descente remplace les saisies du mois, et une liste
  /// tronquée effacerait des retenues.
  static List<PayrollDeductionDto>? listOrNull(Object? raw) {
    if (raw is! List) return null;
    final items = <PayrollDeductionDto>[];
    for (final item in raw) {
      final parsed = tryParse(item);
      if (parsed == null) return null;
      items.add(parsed);
    }
    return items;
  }
}

/// `POST /sync/payroll-deduction-types` — une rubrique du catalogue, dernier
/// écrit gagne par rubrique.
class PayrollDeductionTypeRequestDto {
  final String id;
  final String code;
  final String label;
  final String? description;
  final String currency;
  final int defaultAmountInCents;
  final int sortOrder;
  final bool archived;
  final String clientUpdatedAt;
  final String authorId;

  const PayrollDeductionTypeRequestDto({
    required this.id,
    required this.code,
    required this.label,
    required this.description,
    required this.currency,
    required this.defaultAmountInCents,
    required this.sortOrder,
    required this.archived,
    required this.clientUpdatedAt,
    required this.authorId,
  });

  Map<String, dynamic> toJson() => {
    'deductionType': {
      'id': id,
      'code': code,
      'label': label,
      'description': description,
      'currency': currency,
      'defaultAmountInCents': defaultAmountInCents,
      'sortOrder': sortOrder,
      'archived': archived,
      'clientUpdatedAt': clientUpdatedAt,
    },
    kOutboxAuthorIdKey: authorId,
  };

  static PayrollDeductionTypeRequestDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final inner = raw['deductionType'];
    if (inner is! Map) return null;
    final id = inner.text('id');
    final label = inner.text('label');
    final order = inner.integer('sortOrder');
    final at = inner.instant('clientUpdatedAt');
    final author = raw.text(kOutboxAuthorIdKey);
    if (id == null ||
        label == null ||
        order == null ||
        at == null ||
        author == null) {
      return null;
    }
    return PayrollDeductionTypeRequestDto(
      id: id,
      // Vides sur une rubrique d'un serveur antérieur au contrat : le texte ne
      // les distingue pas d'un champ absent, et l'envoi ne doit pas s'y perdre.
      code: inner.text('code') ?? '',
      label: label,
      description: inner.text('description'),
      currency: inner.text('currency') ?? '',
      defaultAmountInCents: inner.integer('defaultAmountInCents') ?? 0,
      sortOrder: order,
      archived: inner['archived'] == true,
      clientUpdatedAt: at,
      authorId: author,
    );
  }
}

/// `POST /sync/payroll-deductions` — le montant d'un agent sur une rubrique et
/// un mois, dernier écrit gagne par ligne, brouillon seulement.
class PayrollDeductionRequestDto {
  final String month;
  final String staffMemberId;
  final String deductionTypeId;
  final int amountInCents;
  final String currency;
  final String clientUpdatedAt;
  final String authorId;

  const PayrollDeductionRequestDto({
    required this.month,
    required this.staffMemberId,
    required this.deductionTypeId,
    required this.amountInCents,
    required this.currency,
    required this.clientUpdatedAt,
    required this.authorId,
  });

  Map<String, dynamic> toJson() => {
    'deduction': {
      'month': month,
      'staffMemberId': staffMemberId,
      'deductionTypeId': deductionTypeId,
      'amountInCents': amountInCents,
      'currency': currency,
      'clientUpdatedAt': clientUpdatedAt,
    },
    kOutboxAuthorIdKey: authorId,
  };

  static PayrollDeductionRequestDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final inner = raw['deduction'];
    if (inner is! Map) return null;
    final month = inner.yearMonth('month');
    final member = inner.text('staffMemberId');
    final type = inner.text('deductionTypeId');
    final amount = inner.integer('amountInCents');
    final currency = inner.text('currency');
    final at = inner.instant('clientUpdatedAt');
    final author = raw.text(kOutboxAuthorIdKey);
    if (month == null ||
        member == null ||
        type == null ||
        amount == null ||
        currency == null ||
        at == null ||
        author == null) {
      return null;
    }
    return PayrollDeductionRequestDto(
      month: month,
      staffMemberId: member,
      deductionTypeId: type,
      amountInCents: amount,
      currency: currency,
      clientUpdatedAt: at,
      authorId: author,
    );
  }
}
