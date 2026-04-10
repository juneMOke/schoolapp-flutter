enum Gender {
  male,
  female;

  static Gender fromString(String value) {
    switch (value.toUpperCase()) {
      case 'FEMALE':
        return Gender.female;
      case 'MALE':
      default:
        return Gender.male;
    }
  }
}
