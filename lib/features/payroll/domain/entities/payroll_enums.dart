import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Le statut **serveur** d'une paie. « Versée » n'en est pas un : il se
/// dérive (validée et tous les nets versés).
enum PayrollStatus implements StaffWired {
  draft('DRAFT'),
  submitted('SUBMITTED'),
  validated('VALIDATED');

  const PayrollStatus(this.wire);
  @override
  final String wire;

  static PayrollStatus? fromWire(String? value) => staffByWire(values, value);
}

/// Un geste du circuit économe → direction.
enum PayrollGestureKind implements StaffWired {
  /// Brouillon → soumise (`hr.pay.write`).
  submit('SUBMIT'),

  /// Soumise → brouillon, motif obligatoire (`hr.pay.manage`).
  returnToDraft('RETURN'),

  /// Soumise → validée : le serveur recalcule et fige (`hr.pay.manage`).
  validate('VALIDATE'),

  /// Validée → brouillon, motif obligatoire, aucun versement vivant
  /// (`hr.pay.manage`).
  reopen('REOPEN');

  const PayrollGestureKind(this.wire);
  @override
  final String wire;

  static PayrollGestureKind? fromWire(String? value) =>
      staffByWire(values, value);

  bool get needsReason => this == returnToDraft || this == reopen;

  /// Porte l'empreinte de ce qui a été vu.
  bool get carriesFingerprint => this == submit || this == validate;

  /// Le statut où le geste mène.
  PayrollStatus get target => switch (this) {
    submit => PayrollStatus.submitted,
    validate => PayrollStatus.validated,
    returnToDraft || reopen => PayrollStatus.draft,
  };

  /// Le statut d'où il part.
  PayrollStatus get source => switch (this) {
    submit => PayrollStatus.draft,
    returnToDraft || validate => PayrollStatus.submitted,
    reopen => PayrollStatus.validated,
  };
}

/// Comment un salaire ou une avance est versé — le vocabulaire de
/// `FundingSource` (dépenses).
enum PayoutMode implements StaffWired {
  cash('CASH'),
  mobileMoney('MOBILE_MONEY'),
  bank('BANK');

  const PayoutMode(this.wire);
  @override
  final String wire;

  static PayoutMode? fromWire(String? value) => staffByWire(values, value);
}

/// Le motif d'une avance sur salaire.
enum SalaryAdvanceReason implements StaffWired {
  medical('MEDICAL'),
  schooling('SCHOOLING'),
  rent('RENT'),
  bereavement('BEREAVEMENT'),
  transport('TRANSPORT'),
  other('OTHER');

  const SalaryAdvanceReason(this.wire);
  @override
  final String wire;

  static SalaryAdvanceReason? fromWire(String? value) =>
      staffByWire(values, value);
}

/// Par où un bulletin a quitté la tablette — trace locale seulement.
enum PayrollShareChannel implements StaffWired {
  whatsapp('WHATSAPP'),
  pdf('PDF');

  const PayrollShareChannel(this.wire);
  @override
  final String wire;

  static PayrollShareChannel? fromWire(String? value) =>
      staffByWire(values, value);
}
