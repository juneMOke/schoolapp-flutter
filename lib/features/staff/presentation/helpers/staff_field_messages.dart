import 'package:school_app_flutter/features/staff/domain/services/staff_draft_validator.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le texte d'un refus de champ.
abstract final class StaffFieldMessages {
  static String of(AppLocalizations l10n, StaffFieldError error) =>
      switch (error) {
        StaffFieldError.required => l10n.staffFieldRequired,
        StaffFieldError.phoneIncomplete => l10n.staffFieldPhoneIncomplete,
        StaffFieldError.emailInvalid => l10n.staffFieldEmailInvalid,
        StaffFieldError.dateInFuture => l10n.staffFieldDateInFuture,
        StaffFieldError.diplomaIncomplete => l10n.staffFieldDiplomaIncomplete,
      };

  /// Le texte d'erreur de [field] s'il faut le montrer, sinon `null`.
  static String? forField(
    AppLocalizations l10n,
    Map<StaffField, StaffFieldError> visible,
    StaffField field,
  ) {
    final error = visible[field];
    return error == null ? null : of(l10n, error);
  }
}
