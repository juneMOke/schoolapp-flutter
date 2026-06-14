import 'package:school_app_flutter/l10n/app_localizations.dart';

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

  /// Libellé localisé du genre (réutilise les clés `gender*`).
  String getDisplayName(AppLocalizations l10n) => switch (this) {
    StudentGender.male => l10n.genderMale,
    StudentGender.female => l10n.genderFemale,
    StudentGender.other => l10n.genderOther,
  };
}
