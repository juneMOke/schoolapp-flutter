import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/helpers/phone_number_format.dart';
import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';

/// Les champs de la fiche, rangés par étape du formulaire (0 à 3).
enum StaffField {
  lastName(0),
  middleName(0),
  firstName(0),
  sex(0),
  birthDate(0),
  phone(0),
  email(0),
  district(1),
  municipality(1),
  neighborhood(1),
  category(2),
  jobTitle(2),
  entryDate(2),

  /// Les diplômes, jugés d'un bloc : une ligne à moitié remplie.
  diplomas(3);

  const StaffField(this.step);

  /// L'étape qui porte le champ : c'est elle qui rougit, et vers elle qu'on
  /// saute à l'enregistrement.
  final int step;
}

/// Pourquoi un champ est refusé. L'écran choisit le texte.
enum StaffFieldError {
  required,

  /// Ni numéro national complet, ni E.164 (+243 et 9 chiffres).
  phoneIncomplete,
  emailInvalid,

  /// Dans le futur (le serveur refuse `BIRTH_DATE_IN_FUTURE`).
  dateInFuture,

  /// Un diplôme a un niveau sans intitulé, ou l'inverse : le serveur le
  /// refuserait, et l'écarter en silence perdrait la saisie.
  diplomaIncomplete,
}

/// Le verdict d'une fiche : ce qui bloque, et ce qui ne fait qu'avertir.
class StaffDraftValidation extends Equatable {
  final Map<StaffField, StaffFieldError> errors;

  /// Un autre agent porte déjà ce nom complet. Avertissement **non
  /// bloquant** : deux homonymes existent, mais c'est souvent un doublon.
  final bool possibleDuplicate;

  const StaffDraftValidation({
    this.errors = const {},
    this.possibleDuplicate = false,
  });

  bool get isValid => errors.isEmpty;

  Map<StaffField, StaffFieldError> errorsInStep(int step) => {
    for (final entry in errors.entries)
      if (entry.key.step == step) entry.key: entry.value,
  };

  Set<int> get stepsWithErrors => {for (final field in errors.keys) field.step};

  /// La première étape en erreur, ou `null`.
  int? get firstInvalidStep {
    if (errors.isEmpty) return null;
    return stepsWithErrors.reduce((a, b) => a < b ? a : b);
  }

  @override
  List<Object?> get props => [errors, possibleDuplicate];
}

/// Valide une fiche — fonction pure, sans base ni réseau. Les règles sont
/// celles du serveur, jugées avant la mise en file : une fiche refusée des
/// heures plus tard serait loin de celui qui pouvait la corriger.
abstract final class StaffDraftValidator {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static StaffDraftValidation validate(
    StaffMemberDraft draft, {
    required String today,
    List<StaffMember> others = const [],
  }) {
    final errors = <StaffField, StaffFieldError>{};
    void require(StaffField field, String value) {
      if (value.trim().isEmpty) errors[field] = StaffFieldError.required;
    }

    require(StaffField.lastName, draft.lastName);
    require(StaffField.middleName, draft.middleName);
    require(StaffField.firstName, draft.firstName);
    if (draft.sex == null) errors[StaffField.sex] = StaffFieldError.required;

    final birth = draft.birthDate;
    if (birth != null && birth.compareTo(today) > 0) {
      errors[StaffField.birthDate] = StaffFieldError.dateInFuture;
    }

    if (draft.phone.trim().isEmpty) {
      errors[StaffField.phone] = StaffFieldError.required;
    } else if (!PhoneNumberFormat.isValid(draft.phone)) {
      errors[StaffField.phone] = StaffFieldError.phoneIncomplete;
    }
    final email = draft.email.trim();
    if (email.isNotEmpty && !_email.hasMatch(email)) {
      errors[StaffField.email] = StaffFieldError.emailInvalid;
    }

    require(StaffField.district, draft.district);
    require(StaffField.municipality, draft.municipality);
    require(StaffField.neighborhood, draft.neighborhood);

    if (draft.category == null) {
      errors[StaffField.category] = StaffFieldError.required;
    }
    require(StaffField.jobTitle, draft.jobTitle);
    if (draft.entryDate == null) {
      errors[StaffField.entryDate] = StaffFieldError.required;
    }

    final halfFilled = draft.diplomas.any(
      (d) => d.level.trim().isEmpty != d.title.trim().isEmpty,
    );
    if (halfFilled) {
      errors[StaffField.diplomas] = StaffFieldError.diplomaIncomplete;
    }

    return StaffDraftValidation(
      errors: errors,
      possibleDuplicate: _hasHomonym(draft, others),
    );
  }

  static bool _hasHomonym(StaffMemberDraft draft, List<StaffMember> others) {
    String key(String last, String? middle, String first) =>
        SearchNormalizationHelper.normalize(
          [last, middle ?? '', first].map((part) => part.trim()).join('|'),
        );
    if (draft.lastName.trim().isEmpty || draft.firstName.trim().isEmpty) {
      return false;
    }
    final mine = key(draft.lastName, draft.middleName, draft.firstName);
    return others.any(
      (other) =>
          other.id != draft.id &&
          key(other.lastName, other.middleName, other.firstName) == mine,
    );
  }
}
