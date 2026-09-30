import 'dart:convert';

import 'package:school_app_flutter/features/staff/data/sync/staff_member_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_period.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_diploma.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';

/// Une ligne de `staff_members`, et ses deux familles de colonnes.
///
/// - **serveur** : ce que seul le serveur écrit (matricule, frise des
///   contrats, version) — toujours appliqué à la descente ;
/// - **contenu** : ce que le poste saisit — appliqué à la descente seulement
///   quand la ligne n'a aucune saisie locale en attente, sinon la descente
///   écraserait une modification pas encore remontée.
class StaffMemberLocalModel {
  final Map<String, Object?> row;

  const StaffMemberLocalModel(this.row);

  static const String table = 'staff_members';

  static Map<String, Object?> serverColumns(StaffMemberDeltaDto dto) => {
    'staff_number': dto.staffNumber,
    'contracts': jsonEncode([for (final c in dto.contracts) c.toJson()]),
    'version': dto.version,
    'server_updated_at': dto.serverUpdatedAt,
  };

  static Map<String, Object?> contentColumns(StaffMemberDeltaDto dto) => {
    'last_name': dto.lastName,
    'middle_name': dto.middleName,
    'first_name': dto.firstName,
    'sex': dto.sex,
    'birth_date': dto.birthDate,
    'phone_number': dto.phoneNumber,
    'email': dto.email,
    'city': dto.city,
    'district': dto.district,
    'municipality': dto.municipality,
    'neighborhood': dto.neighborhood,
    'address': dto.address,
    'category': dto.category,
    'job_title': dto.jobTitle,
    'entry_date': dto.entryDate,
    'branches': jsonEncode(dto.branches),
    'diplomas': jsonEncode([for (final d in dto.diplomas) d.toJson()]),
    'client_updated_at': dto.clientUpdatedAt,
  };

  String get syncStatus => (row['sync_status'] as String?) ?? '';

  StaffMember toEntity() {
    String? text(String key) => row[key] as String?;
    return StaffMember(
      id: text('id') ?? '',
      staffNumber: text('staff_number'),
      lastName: text('last_name') ?? '',
      middleName: text('middle_name'),
      firstName: text('first_name') ?? '',
      sex: StaffSex.fromWire(text('sex')),
      birthDate: text('birth_date'),
      entryDate: text('entry_date'),
      phoneNumber: text('phone_number'),
      email: text('email'),
      city: text('city'),
      district: text('district'),
      municipality: text('municipality'),
      neighborhood: text('neighborhood'),
      address: text('address'),
      category: StaffCategory.fromWire(text('category')),
      jobTitle: text('job_title'),
      branches: [
        for (final item in _jsonList(text('branches')))
          if (item is String) item,
      ],
      diplomas: [
        for (final item in _jsonList(text('diplomas')))
          if (StaffDiplomaDto.tryParse(item) case final d?)
            StaffDiploma(
              level: d.level,
              title: d.title,
              institution: d.institution,
              graduationYear: d.graduationYear,
            ),
      ],
      contracts: [
        for (final item in _jsonList(text('contracts')))
          if (StaffContractPeriodDto.tryParse(item) case final c?)
            StaffContractPeriod(
              contractId: c.contractId,
              kind: StaffContractKind.fromWire(c.kind),
              payMode: StaffPayMode.fromWire(c.payMode),
              effectiveFrom: c.effectiveFrom,
              endsOn: c.endsOn,
            ),
      ],
      syncState: StaffSyncState.fromDb(text('sync_status')),
    );
  }

  /// Une colonne JSON abîmée se lit comme vide : la fiche reste affichable.
  static List<dynamic> _jsonList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded : const [];
    } on FormatException {
      return const [];
    }
  }
}
