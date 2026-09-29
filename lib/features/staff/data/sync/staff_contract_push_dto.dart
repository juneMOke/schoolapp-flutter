import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_json.dart';

// Modèles de la remontée des contrats : la pose d'une période
// (`POST …/staff-members/{id}/contracts`) et sa correction
// (`POST /sync/staff-contract-corrections`).
//
// ⚠️ Comme pour la fiche, le round-trip `toJson` → `tryParse` EST le chemin du
// push : l'outbox range le texte, le handler le relit.

/// Une période telle que le poste la pose. Les champs étrangers au statut sont
/// envoyés à `null` : le serveur refuse un montant pour un conventionné, un
/// matricule SECOPE pour un permanent.
class StaffContractInputDto {
  final String id;
  final String kind;
  final String? payMode;
  final String effectiveFrom;
  final String? endsOn;
  final int? amountInCents;
  final String? currency;
  final String? secopeNumber;
  final int? bonusInCents;
  final String? bonusCurrency;
  final String recordedAt;

  const StaffContractInputDto({
    required this.id,
    required this.kind,
    required this.effectiveFrom,
    required this.recordedAt,
    this.payMode,
    this.endsOn,
    this.amountInCents,
    this.currency,
    this.secopeNumber,
    this.bonusInCents,
    this.bonusCurrency,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'payMode': payMode,
    'effectiveFrom': effectiveFrom,
    'endsOn': endsOn,
    'amountInCents': amountInCents,
    'currency': currency,
    'secopeNumber': secopeNumber,
    'bonusInCents': bonusInCents,
    'bonusCurrency': bonusCurrency,
    'recordedAt': recordedAt,
  };

  static StaffContractInputDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw.text('id');
    final kind = raw.text('kind');
    final effectiveFrom = raw.day('effectiveFrom');
    final recordedAt = raw.text('recordedAt');
    if (id == null ||
        kind == null ||
        effectiveFrom == null ||
        recordedAt == null) {
      return null;
    }
    return StaffContractInputDto(
      id: id,
      kind: kind,
      payMode: raw.text('payMode'),
      effectiveFrom: effectiveFrom,
      endsOn: raw.day('endsOn'),
      amountInCents: raw.integer('amountInCents'),
      currency: raw.text('currency'),
      secopeNumber: raw.text('secopeNumber'),
      bonusInCents: raw.integer('bonusInCents'),
      bonusCurrency: raw.text('bonusCurrency'),
      recordedAt: recordedAt,
    );
  }
}

/// Le corps d'une pose : l'agent (dans le chemin), la période et l'auteur.
class StaffContractSyncRequestDto {
  final String staffMemberId;
  final StaffContractInputDto contract;
  final String authorId;

  const StaffContractSyncRequestDto({
    required this.staffMemberId,
    required this.contract,
    required this.authorId,
  });

  /// Ce qui part dans le corps — l'agent vit dans le chemin, pas ici.
  Map<String, dynamic> toBody() => {
    'contract': contract.toJson(),
    kOutboxAuthorIdKey: authorId,
  };

  /// Ce que l'outbox range : le corps, plus l'agent du chemin.
  Map<String, dynamic> toJson() => {
    ...toBody(),
    'staffMemberId': staffMemberId,
  };

  static StaffContractSyncRequestDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final staffMemberId = raw.text('staffMemberId');
    final contract = StaffContractInputDto.tryParse(raw['contract']);
    final authorId = raw.text(kOutboxAuthorIdKey);
    if (staffMemberId == null || contract == null || authorId == null) {
      return null;
    }
    return StaffContractSyncRequestDto(
      staffMemberId: staffMemberId,
      contract: contract,
      authorId: authorId,
    );
  }
}

/// Le corps d'une correction : la période fautive, son remplaçant (ou rien —
/// saisie en double) et ce qui était faux.
class StaffContractCorrectionRequestDto {
  final String correctionId;
  final String contractId;

  /// L'agent de la période : sert au poste seul (retrouver la fiche), n'est
  /// pas envoyé.
  final String staffMemberId;
  final String? reason;
  final String correctedAt;
  final StaffContractInputDto? replacement;
  final String authorId;

  const StaffContractCorrectionRequestDto({
    required this.correctionId,
    required this.contractId,
    required this.staffMemberId,
    required this.correctedAt,
    required this.authorId,
    this.reason,
    this.replacement,
  });

  Map<String, dynamic> toBody() => {
    'correctionId': correctionId,
    'contractId': contractId,
    'reason': reason,
    'correctedAt': correctedAt,
    'replacement': replacement?.toJson(),
    kOutboxAuthorIdKey: authorId,
  };

  Map<String, dynamic> toJson() => {
    ...toBody(),
    'staffMemberId': staffMemberId,
  };

  static StaffContractCorrectionRequestDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final correctionId = raw.text('correctionId');
    final contractId = raw.text('contractId');
    final staffMemberId = raw.text('staffMemberId');
    final correctedAt = raw.text('correctedAt');
    final authorId = raw.text(kOutboxAuthorIdKey);
    if (correctionId == null ||
        contractId == null ||
        staffMemberId == null ||
        correctedAt == null ||
        authorId == null) {
      return null;
    }
    final replacementRaw = raw['replacement'];
    final replacement = replacementRaw == null
        ? null
        : StaffContractInputDto.tryParse(replacementRaw);
    // Un remplaçant présent mais illisible ne doit pas se lire « annuler
    // seulement » : ce serait perdre la période juste.
    if (replacementRaw != null && replacement == null) return null;
    return StaffContractCorrectionRequestDto(
      correctionId: correctionId,
      contractId: contractId,
      staffMemberId: staffMemberId,
      reason: raw.text('reason'),
      correctedAt: correctedAt,
      replacement: replacement,
      authorId: authorId,
    );
  }
}

/// L'accusé d'une pose.
class StaffContractSyncResponseDto {
  final StaffContractDeltaDto contract;

  const StaffContractSyncResponseDto(this.contract);

  factory StaffContractSyncResponseDto.fromJson(Map<String, dynamic> json) {
    final contract = StaffContractDeltaDto.tryParse(json['contract']);
    if (contract == null) {
      throw const FormatException('Accusé de contrat illisible');
    }
    return StaffContractSyncResponseDto(contract);
  }
}

/// L'accusé d'une correction : la période corrigée et son remplaçant.
class StaffContractCorrectionResponseDto {
  final StaffContractDeltaDto corrected;
  final StaffContractDeltaDto? replacement;

  const StaffContractCorrectionResponseDto(this.corrected, this.replacement);

  factory StaffContractCorrectionResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final corrected = StaffContractDeltaDto.tryParse(json['corrected']);
    if (corrected == null) {
      throw const FormatException('Accusé de correction illisible');
    }
    return StaffContractCorrectionResponseDto(
      corrected,
      StaffContractDeltaDto.tryParse(json['replacement']),
    );
  }
}
