/// Catalogue des permissions connues du client (ADR-014 §2.6/§2.7).
///
/// **Le typage vit ici, jamais sur le fil.** L'ensemble reçu du serveur reste
/// un ensemble OUVERT de chaînes (`AuthState.permissions`) : une permission
/// inédite y survit intacte, ce qu'un `enum + UNKNOWN` à la désérialisation
/// détruirait en fusionnant toutes les inconnues en un seul jeton. Cet enum ne
/// sert donc **qu'à référencer** les permissions que le code connaît — registre
/// de modules, gardes d'action, garde de route — pour y gagner l'autocomplétion
/// et l'erreur de compilation sur une faute de frappe.
///
/// Ne jamais s'en servir pour parser une réponse serveur : le catalogue serveur
/// peut grandir sans release de l'application, et une valeur absente d'ici doit
/// simplement être ignorée en silence.
///
/// **Une valeur sur le fil ne se renomme pas** (ADR-014 §2.7) : une fois une
/// école seedée, la chaîne est une donnée en base *et* une constante compilée
/// dans l'APK. La renommer imposerait une migration de données **et** une
/// release client. Le test `permissions_test.dart` fige la table complète
/// `(nom, valeur)` pour qu'un glissement ne puisse pas être involontaire.
///
/// Le préfixe est le nom du contexte métier, jamais un synonyme : `finance`
/// (pas `billing`), `enrollment`, `attendance`, `academics`, `discipline`.
enum Perm {
  // ── Inscriptions ──────────────────────────────────────────────────────────
  enrollmentRead('enrollment.read'),
  enrollmentWrite('enrollment.write'),
  enrollmentDelete('enrollment.delete'),
  enrollmentStatsRead('enrollment.stats.read'),

  // ── Finances ──────────────────────────────────────────────────────────────
  // `charge` (créances), `payment` (caisse) et `grid` (grille tarifaire) sont
  // trois autorités distinctes : encaisser n'est pas réécrire les montants de
  // l'école, qui sont sa source unique de vérité monétaire.
  financeChargeRead('finance.charge.read'),
  financeChargeWrite('finance.charge.write'),
  financeChargeDelete('finance.charge.delete'),
  financePaymentRead('finance.payment.read'),
  financePaymentWrite('finance.payment.write'),
  financeGridRead('finance.grid.read'),
  financeGridWrite('finance.grid.write'),
  financeStatsRead('finance.stats.read'),

  // ── Classes ───────────────────────────────────────────────────────────────
  classroomRead('classroom.read'),
  classroomWrite('classroom.write'),
  classroomDelete('classroom.delete'),
  classroomStatsRead('classroom.stats.read'),

  // ── Présence ──────────────────────────────────────────────────────────────
  attendanceRead('attendance.read'),
  attendanceWrite('attendance.write'),
  attendanceDelete('attendance.delete'),
  attendanceStatsRead('attendance.stats.read'),

  // ── Discipline ────────────────────────────────────────────────────────────
  disciplineRead('discipline.read'),
  disciplineWrite('discipline.write'),
  disciplineDelete('discipline.delete'),

  // ── Académique ────────────────────────────────────────────────────────────
  // `academicsGradeSeal` est délibérément séparée de `academicsGradeWrite` :
  // sceller un bulletin n'est pas saisir les notes qui le composent.
  academicsCourseRead('academics.course.read'),
  academicsCourseWrite('academics.course.write'),
  academicsCourseDelete('academics.course.delete'),
  academicsGradeRead('academics.grade.read'),
  academicsGradeWrite('academics.grade.write'),
  academicsGradeSeal('academics.grade.seal'),
  academicsResultRead('academics.result.read'),
  academicsReferentialRead('academics.referential.read'),
  academicsReferentialWrite('academics.referential.write'),

  // ── Éditique ──────────────────────────────────────────────────────────────
  // `editiqueCancel` est séparée de `editiqueWrite` : une pièce émise ne se
  // supprime pas, elle s'annule — et annuler n'est pas produire.
  editiqueRead('editique.read'),
  editiqueWrite('editique.write'),
  editiqueCancel('editique.cancel'),

  // ── École ─────────────────────────────────────────────────────────────────
  schoolRead('school.read'),
  schoolWrite('school.write'),

  // ── Élèves ────────────────────────────────────────────────────────────────
  studentRead('student.read'),
  studentWrite('student.write'),

  // ── Enseignants ───────────────────────────────────────────────────────────
  teacherRead('teacher.read'),
  teacherWrite('teacher.write'),

  // ── Emploi du temps ───────────────────────────────────────────────────────
  scheduleRead('schedule.read'),
  scheduleWrite('schedule.write'),

  // ── Administration (aucun consommateur dans l'APK à ce jour) ──────────────
  // Comptes et définitions de rôle : ces écrans vivent côté serveur/back-office.
  // Elles sont déclarées ici pour que le catalogue client reste le miroir exact
  // du catalogue serveur — c'est ce miroir qui rend une dérive détectable.
  authUserRead('auth.user.read'),
  authUserWrite('auth.user.write'),
  authPermissionRead('auth.permission.read'),
  authPermissionWrite('auth.permission.write'),

  // ── Périmètre PLATEFORME — hors du modèle scopé-école ─────────────────────
  /// **Ne peut jamais apparaître dans un ensemble effectif.** Le provisionnement
  /// d'établissement n'appartient à aucune école : la permission n'est jamais
  /// semée, l'édition la refuse, et le résolveur l'ignore (ADR-014 §2.13). La
  /// déclarer ici n'ouvre donc rien — elle existe pour que le miroir du
  /// catalogue soit complet, et pour qu'un `PermissionGate` qui la référencerait
  /// un jour se lise immédiatement comme une impasse.
  platformSchoolProvision('platform.school.provision');

  const Perm(this.wire);

  /// Valeur telle qu'elle circule dans `LoginResponse.permissions` et telle
  /// qu'elle est stockée en base côté serveur. C'est cette chaîne — jamais le
  /// nom Dart — qu'on cherche dans l'ensemble effectif d'une session.
  final String wire;
}
