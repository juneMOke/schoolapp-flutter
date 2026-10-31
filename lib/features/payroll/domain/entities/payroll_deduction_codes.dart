/// Les codes de refus des rubriques de l'école.
abstract final class PayrollDeductionCodes {
  /// Rangé sur une saisie dont la rubrique a été refusée.
  static const String typeRefused = 'DEDUCTION_TYPE_REFUSED';

  /// 409 d'attente : la saisie vise une rubrique que le serveur n'a pas reçue.
  static const String typeNotYetSynced = 'DEDUCTION_TYPE_NOT_YET_SYNCED';

  /// 410 : la rubrique visée a été supprimée.
  static const String tombstoned = 'AGGREGATE_TOMBSTONED';
  static const String invalidType = 'INVALID_DEDUCTION_TYPE';
  static const String labelTaken = 'DEDUCTION_TYPE_LABEL_TAKEN';
  static const String limitReached = 'DEDUCTION_TYPE_LIMIT_REACHED';
  static const String codeTaken = 'DEDUCTION_TYPE_CODE_TAKEN';
  static const String fieldLocked = 'DEDUCTION_TYPE_FIELD_LOCKED';
  static const String currencyUnknown = 'DEDUCTION_TYPE_CURRENCY_UNKNOWN';
  static const String inUse = 'DEDUCTION_TYPE_IN_USE';
  static const String archived = 'DEDUCTION_TYPE_ARCHIVED';
  static const String currencyMismatch = 'DEDUCTION_CURRENCY_MISMATCH';
}
