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
