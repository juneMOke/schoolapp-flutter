/// Les agrégats d'outbox de la paie, et les clés qui les ordonnent.
///
/// Le moteur n'ordonne rien par agrégat ; les handlers de la paie le font par
/// `OutboxDao.hasOlderPending`, sur l'`aggregateId` posé ici :
/// - le **mois** (`payroll:YYYY-MM`) : éléments variables, gestes, et l'avance
///   qui commence ce mois-là — un geste attend ce qui a été écrit avant lui ;
/// - la **ligne** (`payroll-line:YYYY-MM:<agent>`) : versements et
///   annulations d'un même salaire, dans l'ordre de pose ;
/// - l'**avance** (`advance:<id>`) : son annulation attend son octroi.
abstract final class PayrollOutbox {
  static const String settings = 'PAYROLL_SETTINGS';
  static const String profile = 'STAFF_PAY_PROFILE';
  static const String variables = 'PAYROLL_VARIABLES';
  static const String gesture = 'PAYROLL_GESTURE';
  static const String advance = 'SALARY_ADVANCE';
  static const String advanceCancellation = 'SALARY_ADVANCE_CANCELLATION';
  static const String disbursement = 'PAYROLL_DISBURSEMENT';
  static const String disbursementCancellation =
      'PAYROLL_DISBURSEMENT_CANCELLATION';

  static String entryId(String type, String id) => '$type:$id';

  static String monthKey(String month) => 'payroll:$month';

  static String lineKey(String month, String staffMemberId) =>
      'payroll-line:$month:$staffMemberId';

  static String advanceKey(String advanceId) => 'advance:$advanceId';
}
