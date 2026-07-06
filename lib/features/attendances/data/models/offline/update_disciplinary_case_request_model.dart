import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';

/// Corps du `PUT /api/v1/disciplinary-cases/{id}` (DF-2, traitement régime C).
///
/// ⚠️ **Toujours renvoyer la sanction COURANTE** : tant que le back n'ignore pas
/// les `null` (DG-3), omettre la sanction l'efface. `expectedVersion` = verrou
/// optimiste (409 si périmé → refetch + rejeu LWW). Sert aussi de payload
/// d'outbox (UPDATE) ; `caseId` porté par `OutboxEntry.aggregateId`.
class UpdateDisciplinaryCaseRequestModel extends Equatable {
  final String status;
  final String? sanction;
  final int? expectedVersion;

  const UpdateDisciplinaryCaseRequestModel({
    required this.status,
    this.sanction,
    this.expectedVersion,
  });

  factory UpdateDisciplinaryCaseRequestModel.fromDomain({
    required DisciplinaryStatus status,
    DisciplinarySanction? sanction,
    int? expectedVersion,
  }) => UpdateDisciplinaryCaseRequestModel(
    status: status.toApiValue(),
    sanction: sanction?.toApiValue(),
    expectedVersion: expectedVersion,
  );

  factory UpdateDisciplinaryCaseRequestModel.fromJson(
    Map<String, dynamic> json,
  ) => UpdateDisciplinaryCaseRequestModel(
    status: (json['status'] as String?) ?? 'OPEN',
    sanction: json['sanction'] as String?,
    expectedVersion: (json['expectedVersion'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'status': status,
    // Toujours présent (peut être null) : renvoie la sanction courante.
    'sanction': sanction,
    if (expectedVersion != null) 'expectedVersion': expectedVersion,
  };

  String toJsonString() => jsonEncode(toJson());

  factory UpdateDisciplinaryCaseRequestModel.fromJsonString(String payload) =>
      UpdateDisciplinaryCaseRequestModel.fromJson(
        jsonDecode(payload) as Map<String, dynamic>,
      );

  @override
  List<Object?> get props => [status, sanction, expectedVersion];
}
