import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';

/// Droits qu'exige la **poussée** d'une écriture de la file (ADR-014 §13.3).
///
/// Lus par la pré-garde du moteur (`OutboxWriteAccess`). Chaque valeur recopie
/// **exactement** le `@RequiresPermission` de la route `/sync` visée — jamais
/// plus. Une pré-garde plus stricte que le serveur retiendrait pour toujours
/// une écriture qu'il aurait acceptée : c'est pourquoi certaines constantes
/// d'écran du registre, qui exigent davantage pour offrir le geste, ne
/// servent pas ici.
///
/// Quand l'exigence d'écran et celle de la route coïncident, le handler lit
/// directement la constante du registre (`kAttendanceRecordAccess`,
/// `kPaymentCollectAccess`…). Ce fichier ne nomme que les autres.
///
/// Les contrôles de droit faits dans le **code** du serveur s'y ajoutent quand
/// la tablette sait les reconnaître sur l'entrée (clore ou rouvrir le mois du
/// pointage, gestes de direction de la paie, avance au personnel, remplacement
/// d'un versement). Celui qu'elle ne peut pas lire — corriger l'appel d'un jour
/// passé, que seul le serveur sait déjà saisi — reste à la sonde du moteur.

/// `POST /sync/attendance-closures`, `POST /sync/attendance-justifications/
/// {id}/decision` — `attendance.amend` seul. L'écran exige en plus
/// `attendance.write` ([kAttendanceAmendAccess]) ; la route, non.
const ModuleAccess kAttendanceAmendPushAccess = ModuleAccess([
  Perm.attendanceAmend,
]);

/// `POST /sync/payment-corrections` — `finance.payment.cancel` ET
/// `editique.cancel`. Un remplacement exige en plus `finance.payment.write` et
/// `editique.write`, mais ce contrôle vit dans le code du contrôleur : la sonde
/// rattrape son 403.
const ModuleAccess kPaymentCorrectionPushAccess = ModuleAccess([
  Perm.financePaymentCancel,
  Perm.editiqueCancel,
], requiresAll: true);

/// `POST /sync/staff-members/{id}/documents` — `hr.document.write`.
const ModuleAccess kStaffDocumentPushAccess = ModuleAccess([
  Perm.hrDocumentWrite,
]);

/// `POST /sync/academics/evaluations`, `/notes`, `PUT …/sujet`,
/// `POST …/copie-log` — `academics.grade.write`.
const ModuleAccess kGradeWritePushAccess = ModuleAccess([
  Perm.academicsGradeWrite,
]);

/// `POST /sync/schedule/draft-cells` — `schedule.write` : construire le
/// brouillon d'un emploi du temps (direction, conseiller, secrétariat).
const ModuleAccess kScheduleWritePushAccess = ModuleAccess([
  Perm.scheduleWrite,
]);

/// `POST /sync/calendar/events` — un des trois droits d'écriture par nature
/// (K10) ; le serveur refuse ligne à ligne une nature hors du droit
/// (`CALENDAR_NATURE_FORBIDDEN`).
const ModuleAccess kCalendarEventPushAccess = ModuleAccess([
  Perm.calendarAssessmentWrite,
  Perm.calendarLifeWrite,
  Perm.calendarHolidayWrite,
]);

/// `POST /sync/academics/cotes` — `academics.grade.enter`.
const ModuleAccess kGradeEnterPushAccess = ModuleAccess([
  Perm.academicsGradeEnter,
]);

/// `POST|PUT|DELETE /sync/academics/chapitres…`, `/chapitre-notes`,
/// `/cours/{id}/chapitres-ordre`, `/journal` — `academics.programme.write`.
const ModuleAccess kProgrammeWritePushAccess = ModuleAccess([
  Perm.academicsProgrammeWrite,
]);

/// `POST /sync/classroom-transfers` — `classroom.write`.
const ModuleAccess kClassroomWritePushAccess = ModuleAccess([
  Perm.classroomWrite,
]);

/// `POST /sync/payment-corrections` avec un remplaçant : le contrôleur exige en
/// plus `finance.payment.write` ET `editique.write`.
const ModuleAccess kPaymentReplacementPushAccess = ModuleAccess([
  Perm.financePaymentCancel,
  Perm.editiqueCancel,
  Perm.financePaymentWrite,
  Perm.editiqueWrite,
], requiresAll: true);

/// `POST /sync/expenses` d'une avance au personnel : `expense.write` sur la
/// route, `hr.pay.read` dans le code (`STAFF_ADVANCE_FORBIDDEN`).
const ModuleAccess kStaffAdvancePushAccess = ModuleAccess([
  Perm.expenseWrite,
  Perm.hrPayRead,
], requiresAll: true);

/// `POST /sync/staff-attendance-locks`, `CLOSE_MONTH` : `hr.attendance.write`
/// sur la route, `hr.attendance.manage` dans le code
/// (`MONTH_CLOSURE_FORBIDDEN`).
const ModuleAccess kStaffMonthClosePushAccess = ModuleAccess([
  Perm.hrAttendanceWrite,
  Perm.hrAttendanceManage,
], requiresAll: true);

/// `POST /sync/staff-attendance-locks`, `REOPEN_MONTH` : `hr.attendance.write`
/// sur la route, `hr.attendance.reopen` dans le code
/// (`MONTH_REOPEN_FORBIDDEN`).
const ModuleAccess kStaffMonthReopenPushAccess = ModuleAccess([
  Perm.hrAttendanceWrite,
  Perm.hrAttendanceReopen,
], requiresAll: true);

/// `POST /sync/payroll-gestures` hors `SUBMIT` (renvoyer, valider, rouvrir) :
/// `hr.pay.write` sur la route, `hr.pay.manage` dans le code
/// (`PAYROLL_GESTURE_FORBIDDEN`).
const ModuleAccess kPayrollDirectionGesturePushAccess = ModuleAccess([
  Perm.hrPayWrite,
  Perm.hrPayManage,
], requiresAll: true);
