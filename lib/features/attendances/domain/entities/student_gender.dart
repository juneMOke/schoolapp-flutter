enum StudentGender { male, female, other }

extension StudentGenderX on StudentGender {
  static StudentGender fromApiValue(String value) =>
      switch (value.toUpperCase()) {
        'MALE' => StudentGender.male,
        'FEMALE' => StudentGender.female,
        _ => StudentGender.other,
      };

  String toApiValue() => switch (this) {
    StudentGender.male => 'MALE',
    StudentGender.female => 'FEMALE',
    StudentGender.other => 'OTHER',
  };
}
