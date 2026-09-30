import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_json.dart';

/// Le profil de paie d'un agent sur le fil — la même forme dans les deux
/// sens, arbitrée au dernier écrit (`clientUpdatedAt`).
class StaffPayProfileDto {
  final String staffMemberId;
  final int dependentChildren;
  final String? preferredMode;
  final String? operator;
  final String? payoutPhone;
  final String? bankName;
  final String? bankAccount;
  final String clientUpdatedAt;
  final String? serverUpdatedAt;

  const StaffPayProfileDto({
    required this.staffMemberId,
    required this.dependentChildren,
    required this.clientUpdatedAt,
    this.preferredMode,
    this.operator,
    this.payoutPhone,
    this.bankName,
    this.bankAccount,
    this.serverUpdatedAt,
  });

  Map<String, dynamic> toJson() => {
    'staffMemberId': staffMemberId,
    'dependentChildren': dependentChildren,
    'preferredMode': preferredMode,
    'operator': operator,
    'payoutPhone': payoutPhone,
    'bankName': bankName,
    'bankAccount': bankAccount,
    'clientUpdatedAt': clientUpdatedAt,
  };

  static StaffPayProfileDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final inner = raw['profile'];
    if (inner is Map) return tryParse(inner);
    final id = raw.text('staffMemberId');
    final at = raw.instant('clientUpdatedAt');
    if (id == null || at == null) return null;
    return StaffPayProfileDto(
      staffMemberId: id,
      dependentChildren: raw.integer('dependentChildren') ?? 0,
      preferredMode: raw.text('preferredMode'),
      operator: raw.text('operator'),
      payoutPhone: raw.text('payoutPhone'),
      bankName: raw.text('bankName'),
      bankAccount: raw.text('bankAccount'),
      clientUpdatedAt: at,
      serverUpdatedAt: raw.instant('serverUpdatedAt'),
    );
  }

  factory StaffPayProfileDto.fromJson(Map<String, dynamic> json) =>
      tryParse(json) ?? (throw const FormatException('Profil illisible'));
}

class StaffPayProfileRequestDto {
  final StaffPayProfileDto profile;
  final String authorId;

  const StaffPayProfileRequestDto({
    required this.profile,
    required this.authorId,
  });

  Map<String, dynamic> toJson() => {
    'profile': profile.toJson(),
    kOutboxAuthorIdKey: authorId,
  };

  static StaffPayProfileRequestDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final profile = StaffPayProfileDto.tryParse(raw['profile']);
    final author = raw.text(kOutboxAuthorIdKey);
    if (profile == null || author == null) return null;
    return StaffPayProfileRequestDto(profile: profile, authorId: author);
  }
}

class StaffPayProfilePageDto extends ParsedKeysetPage<StaffPayProfileDto> {
  StaffPayProfilePageDto._(ParsedKeysetPage<StaffPayProfileDto> parsed)
    : super(items: parsed.items, page: parsed.page, skipped: parsed.skipped);

  factory StaffPayProfilePageDto.fromJson(Map<String, dynamic> json) =>
      StaffPayProfilePageDto._(
        ParsedKeysetPage.fromJson(json, StaffPayProfileDto.tryParse),
      );
}
