import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentSummaryUtils {
  static String fallbackValue(AppLocalizations l10n, String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? l10n.facturationDetailUnknownValue : trimmed;
  }

  static String genderLabel(String genderName, AppLocalizations l10n) {
    return switch (genderName.toLowerCase()) {
      'male' => l10n.genderMale,
      'female' => l10n.genderFemale,
      _ => l10n.facturationDetailUnknownValue,
    };
  }

  static String relationshipLabel(
    RelationshipType type,
    AppLocalizations l10n,
  ) {
    return switch (type) {
      RelationshipType.father => l10n.relationshipFather,
      RelationshipType.mother => l10n.relationshipMother,
      RelationshipType.guardian => l10n.relationshipGuardian,
      RelationshipType.other => l10n.relationshipOther,
      RelationshipType.uncle => l10n.relationshipUncle,
      RelationshipType.aunt => l10n.relationshipAunt,
      RelationshipType.grandparent => l10n.relationshipGrandparent,
    };
  }

  static String resolveTargetGroupName({
    required AcademicYearContext? bootstrap,
    required String groupId,
    required String fallbackName,
  }) {
    final candidate = fallbackName.trim();
    if (candidate.isNotEmpty) return candidate;

    final id = groupId.trim();
    if (id.isEmpty) return '';

    if (bootstrap != null) {
      for (final bundle in bootstrap.schoolLevelGroups) {
        if (bundle.group.id == id) {
          final name = bundle.group.name.trim();
          if (name.isNotEmpty) return name;
          break;
        }
      }
    }

    return id;
  }

  static String resolveTargetLevelName({
    required AcademicYearContext? bootstrap,
    required String groupId,
    required String levelId,
    required String fallbackName,
  }) {
    final candidate = fallbackName.trim();
    if (candidate.isNotEmpty) return candidate;

    final group = groupId.trim();
    final level = levelId.trim();
    if (level.isEmpty) return '';

    if (bootstrap != null) {
      for (final groupBundle in bootstrap.schoolLevelGroups) {
        if (group.isNotEmpty && groupBundle.group.id != group) {
          continue;
        }

        for (final schoolLevel in groupBundle.levels) {
          if (schoolLevel.id == level) {
            final name = schoolLevel.name.trim();
            if (name.isNotEmpty) return name;
            return level;
          }
        }
      }
    }

    return level;
  }
}
