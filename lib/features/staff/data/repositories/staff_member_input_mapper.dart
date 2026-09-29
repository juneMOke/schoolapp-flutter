import 'package:school_app_flutter/core/helpers/phone_number_format.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_push_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';

/// Passe d'une fiche saisie à ce qui part au serveur : champs rognés, facultatifs
/// vides mis à `null`, téléphone en E.164, diplômes entièrement vides écartés,
/// matières seulement pour un enseignant.
///
/// Rend `null` si la fiche est incomplète : elle aurait dû être refusée par la
/// validation, et le dépôt ne fabrique pas de valeur à sa place.
abstract final class StaffMemberInputMapper {
  static StaffMemberInputDto? of(
    StaffMemberDraft draft, {
    required String clientUpdatedAt,
  }) {
    final sex = draft.sex;
    final category = draft.category;
    final entryDate = draft.entryDate;
    if (sex == null || category == null || entryDate == null) return null;
    String? optional(String value) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return StaffMemberInputDto(
      id: draft.id,
      lastName: draft.lastName.trim(),
      middleName: draft.middleName.trim(),
      firstName: draft.firstName.trim(),
      sex: sex.wire,
      birthDate: draft.birthDate,
      phoneNumber: PhoneNumberFormat.canonicalE164(draft.phone),
      email: optional(draft.email),
      city: optional(draft.city),
      district: draft.district.trim(),
      municipality: draft.municipality.trim(),
      neighborhood: draft.neighborhood.trim(),
      address: optional(draft.address),
      category: category.wire,
      jobTitle: draft.jobTitle.trim(),
      entryDate: entryDate,
      branches: draft.isTeacher
          ? [
              for (final branch in draft.branches)
                if (branch.trim().isNotEmpty) branch.trim(),
            ]
          : const [],
      diplomas: [
        for (final diploma in draft.diplomas)
          if (diploma.level.trim().isNotEmpty &&
              diploma.title.trim().isNotEmpty)
            StaffDiplomaDto(
              level: diploma.level.trim(),
              title: diploma.title.trim(),
              institution: optional(diploma.institution ?? ''),
              graduationYear: diploma.graduationYear,
            ),
      ],
      clientUpdatedAt: clientUpdatedAt,
    );
  }
}
