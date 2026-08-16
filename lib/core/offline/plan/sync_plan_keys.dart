/// La table d'alias `planKey` ↔ `clientResource` — **le seul endroit du dépôt**
/// où la clé serveur d'un flux rencontre la clé locale du handler qui le tire
/// (ADR-015 F3).
///
/// ## Pourquoi une table, et pas une translittération
///
/// Cinq correspondances cassent toute règle mécanique :
/// `school.referential` → `enrollment_referential` (le module a été renommé),
/// `enrollment.snapshots` → `enrollments` (second membre, sans rapport avec la
/// clé), `classroom.classrooms` → `classrooms` (préfixe dédoublé),
/// `attendance.records` → `attendance` (suffixe tombé), `discipline.cases` →
/// `disciplinary_cases` (discipline → disciplinary). Les treize autres se
/// déduiraient de `.`/`-` → `_`, mais une règle qui échoue une fois sur quatre
/// n'est pas une règle.
///
/// ## Ce qui la garde honnête
///
/// Rien, sinon le test qui l'accompagne. Une clé mal orthographiée ici donne un
/// flux **présent au plan et jamais tiré**, sans erreur, sans log — et sous le
/// lot F5, où le plan devient l'autorité, ce n'est plus une dégradation mais
/// l'arrêt total de ce flux. Le test énumère donc les handlers **réellement
/// enregistrés sur le `PullCoordinator`**, jamais une liste recopiée à la main :
/// une liste recopiée dériverait avec le code au lieu de le contredire.
///
/// ## L'invariant, et pourquoi ce n'est pas une bijection
///
/// **Tout `PullHandler` enregistré est couvert par exactement une [planKeyOf],
/// et toute clé de [kSyncPlanAliases] couvre au moins un handler.**
///
/// Dix-huit clés pour dix-neuf handlers, et ce n'est pas une erreur de compte :
/// `enrollment.snapshots` porte **deux** ressources, l'hydratant et le delta.
/// Le serveur les a fusionnées sous une clé unique précisément pour rendre leur
/// arête d'ordre indéclarable, donc incassable.
///
/// ⚠️ `enrollment.deltas` **n'existe pas** dans le contrat déployé. Le catalogue
/// V1.2 le liste encore comme un flux à part ; l'énumération serveur l'a
/// fusionné. L'inscrire ici produirait exactement le défaut que ce fichier
/// existe à prévenir : une clé jamais présente au plan, et `enrollments`
/// recensé deux fois.
///
/// ## Ce que `clientResource` n'est pas
///
/// Ce n'est pas une clé de `sync_meta`. C'est la clé de routage du registre, le
/// sujet du `PullCompletionBus` et la clé de déduplication — et pour plusieurs
/// flux, seulement un **préfixe** de clé de curseur. Voir [isCursorKeyPrefix].
library;

/// Les dix-huit clés de flux du contrat, dans l'ordre de l'énumération serveur.
///
/// Recopiées de `SyncStream.java`, **jamais** du catalogue en Markdown : le
/// catalogue est un relevé daté, l'énumération est ce qui est déployé.
abstract final class SyncPlanKeys {
  static const String schoolReferential = 'school.referential';
  static const String enrollmentSnapshots = 'enrollment.snapshots';
  static const String enrollmentReenrollmentCohort =
      'enrollment.reenrollment-cohort';
  static const String enrollmentPreEnrollments = 'enrollment.pre-enrollments';
  static const String classroomClassrooms = 'classroom.classrooms';
  static const String classroomMembers = 'classroom.members';
  static const String classroomTransfers = 'classroom.transfers';
  static const String financeStudentCharges = 'finance.student-charges';
  static const String financePayments = 'finance.payments';
  static const String attendanceRecords = 'attendance.records';
  static const String disciplineCases = 'discipline.cases';
  static const String scheduleTimeSlots = 'schedule.time-slots';
  static const String scheduleSessions = 'schedule.sessions';
  static const String academicsGradesReferential =
      'academics.grades-referential';
  static const String academicsCours = 'academics.cours';
  static const String academicsEvaluations = 'academics.evaluations';
  static const String academicsNotes = 'academics.notes';
  static const String editiqueDocuments = 'editique.documents';
}

/// `planKey` → les `PullHandler.resource` qu'elle couvre.
///
/// L'ordre de la liste est **porteur** pour `enrollment.snapshots` : l'hydratant
/// (`enrollment_snapshots`, qui INSERT) précède le delta (`enrollments`, qui ne
/// fait qu'UPDATE). Inverser la paire laisserait le delta sans lignes à mettre à
/// jour — des dossiers muets, sans erreur. D'où une `List`, jamais un `Set` :
/// un ensemble n'a pas d'ordre à préserver.
const Map<String, List<String>> kSyncPlanAliases = {
  SyncPlanKeys.schoolReferential: ['enrollment_referential'],
  SyncPlanKeys.enrollmentSnapshots: ['enrollment_snapshots', 'enrollments'],
  SyncPlanKeys.enrollmentReenrollmentCohort: ['enrollment_reenrollment_cohort'],
  SyncPlanKeys.enrollmentPreEnrollments: ['enrollment_pre_enrollments'],
  SyncPlanKeys.classroomClassrooms: ['classrooms'],
  SyncPlanKeys.classroomMembers: ['classroom_members'],
  SyncPlanKeys.classroomTransfers: ['classroom_transfers'],
  SyncPlanKeys.financeStudentCharges: ['finance_student_charges'],
  SyncPlanKeys.financePayments: ['finance_payments'],
  SyncPlanKeys.attendanceRecords: ['attendance'],
  SyncPlanKeys.disciplineCases: ['disciplinary_cases'],
  SyncPlanKeys.scheduleTimeSlots: ['schedule_time_slots'],
  SyncPlanKeys.scheduleSessions: ['schedule_sessions'],
  SyncPlanKeys.academicsGradesReferential: ['academics_grades_referential'],
  SyncPlanKeys.academicsCours: ['academics_cours'],
  SyncPlanKeys.academicsEvaluations: ['academics_evaluations'],
  SyncPlanKeys.academicsNotes: ['academics_notes'],
  SyncPlanKeys.editiqueDocuments: ['editique_documents'],
};

/// L'index inverse, construit une fois : `PullHandler.resource` → `planKey`.
///
/// Calculé plutôt qu'écrit à la main — deux tables tenues en parallèle
/// divergent, et celle-ci se contredirait en silence.
final Map<String, String> _planKeyByResource = {
  for (final entry in kSyncPlanAliases.entries)
    for (final resource in entry.value) resource: entry.key,
};

/// La clé de plan qui couvre cette ressource de handler, ou `null` si aucune.
///
/// `null` est un **défaut de contrat**, pas un cas nominal : c'est un handler
/// que le plan ne pourra jamais désigner. Le coordinateur le comptabilise dans
/// `PullRunReport.plannedNotPulledKeys` plutôt que de le taire.
String? planKeyOf(String resource) => _planKeyByResource[resource];

/// Les ressources couvertes par cette clé, dans l'ordre porteur. Vide si la clé
/// est inconnue de ce client.
///
/// Une clé inconnue n'est **pas** une erreur : le contrat prévoit qu'un flux
/// soit introduit côté serveur avant que le client sache le traiter. Elle doit
/// seulement laisser une trace.
List<String> resourcesOf(String planKey) =>
    kSyncPlanAliases[planKey] ?? const <String>[];

/// Vrai si la ressource n'est qu'un **préfixe** de clé de curseur, jamais une
/// clé complète — auquel cas interroger `sync_meta` sur la ressource nue rend
/// toujours `null`, et conclure « ce flux n'a jamais été tiré » serait faux.
///
/// Le contrat annonce la règle « FANOUT ⇒ préfixe ». Elle est **incomplète** :
/// deux flux `KEYSET`/`COHORT` portent eux aussi un suffixe, parce que leur
/// curseur est scopé par école ou par année.
///
/// | ressource | clé réelle en base |
/// |---|---|
/// | `academics_cours` | `academics_cours@<uid>` |
/// | `academics_evaluations` | `academics_evaluations:<coursId>` |
/// | `academics_notes` | `academics_notes:<coursId>` |
/// | `academics_grades_referential` | `academics_grades_referential@<uid>` |
/// | `schedule_sessions` | `schedule_sessions@<uid>` |
/// | `editique_documents` | `editique_documents@<schoolId>` |
/// | `enrollment_reenrollment_cohort` | `…:<yearId>`, nue en repli |
///
/// D'où une liste explicite plutôt qu'une déduction depuis `mode`/`scope` : la
/// déduction serait fausse sur les trois dernières lignes.
bool isCursorKeyPrefix(String resource) =>
    _kCursorKeyPrefixes.contains(resource);

const Set<String> _kCursorKeyPrefixes = {
  'academics_cours',
  'academics_evaluations',
  'academics_notes',
  'academics_grades_referential',
  'schedule_sessions',
  'editique_documents',
  'enrollment_reenrollment_cohort',
};
