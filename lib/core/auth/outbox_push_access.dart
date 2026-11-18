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
/// Les contrôles faits dans le code du serveur, et non sur la route (corriger
/// l'appel d'un jour passé, remplacer un versement), n'y figurent pas : la
/// sonde du moteur rattrape leur 403.

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
