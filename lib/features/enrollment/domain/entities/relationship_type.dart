import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';

enum RelationshipType {
  father,
  mother,
  guardian,
  uncle,
  aunt,
  grandparent,
  other;

  static RelationshipType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'MOTHER':
        return RelationshipType.mother;
      case 'GUARDIAN':
        return RelationshipType.guardian;
      case 'UNCLE':
        return RelationshipType.uncle;
      case 'AUNT':
        return RelationshipType.aunt;
      case 'GRANDPARENT':
        return RelationshipType.grandparent;
      case 'FATHER':
        return RelationshipType.father;
      case 'OTHER':
      default:
        return RelationshipType.other;
    }
  }
}

extension RelationshipTypeColorExtension on RelationshipType {
  Color getColor() => switch (this) {
    RelationshipType.father => AppColors.relationshipFather,
    RelationshipType.mother => AppColors.relationshipMother,
    RelationshipType.guardian => AppColors.relationshipGuardian,
    RelationshipType.uncle => AppColors.relationshipUncle,
    RelationshipType.aunt => AppColors.relationshipAunt,
    RelationshipType.grandparent => AppColors.relationshipGrandparent,
    RelationshipType.other => AppColors.relationshipOther,
  };
}
