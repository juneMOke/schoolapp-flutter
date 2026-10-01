import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';

/// La recherche d'un agent, partagée par le fichier du personnel et le
/// Pointage : chaque mot tapé doit se trouver quelque part — nom, post-nom,
/// prénom, matricule, fonction ou matières —, sans égard à la casse ni aux
/// accents.
abstract final class StaffMemberSearch {
  static bool matches(StaffMember member, String text) =>
      SearchNormalizationHelper.containsAllWords([
        member.lastName,
        member.middleName,
        member.firstName,
        member.staffNumber,
        member.jobTitle,
        ...member.branches,
      ], text);
}
