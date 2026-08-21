import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/plan/pull_sequencer.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_keys.dart';

/// Un flux du plan réduit à ce que le séquenceur regarde : sa clé et ses
/// dépendances. Tout le reste (mode, scope, reason) lui est invisible.
typedef Flow = (String key, List<String> dependsOn);

/// Fabrique un [SyncPlan] depuis une liste de `(clé, dependsOn)`.
///
/// `clientResource` est renseigné depuis l'alias pour rester fidèle à ce que le
/// serveur enverrait — le séquenceur ne le lit pas, il repasse par
/// `resourcesOf`, et un test qui le renseignerait de travers ne s'en
/// apercevrait pas.
SyncPlan planOf(List<Flow> flows) => SyncPlan(
  planVersion: 1,
  subject: 'uid-serveur-1',
  onAbsence: 'ignore',
  streams: [
    for (final (key, dependsOn) in flows)
      SyncPlanFlow(
        key: key,
        clientResource: resourcesOf(key),
        mode: SyncFlowMode.keyset,
        scope: SyncFlowScope.school,
        reason: const ['socle'],
        dependsOn: dependsOn,
      ),
  ],
);

/// Le même, quand aucun flux ne déclare de dépendance.
SyncPlan planOfKeys(List<String> keys) =>
    planOf([for (final key in keys) (key, const <String>[])]);

/// L'arête money-grade `before → after`, telle qu'elle est déclarée en prod.
///
/// Cherchée dans [kMoneyGradeEdges] plutôt que reconstruite : le test doit
/// rougir si l'arête disparaît de la constante, pas fabriquer la sienne.
MoneyGradeEdge edgeBetween(String before, String after) =>
    kMoneyGradeEdges.firstWhere(
      (e) => e.before == before && e.after == after,
      orElse: () => throw StateError('arête $before → $after absente'),
    );

void main() {
  group('repli sans plan — le lot ne change rien tant que le plan ne gouverne '
      'pas', () {
    test('plan absent : l\'ordre d\'enregistrement, tel quel', () {
      const registered = [
        'finance_payments',
        'enrollment_referential',
        'classrooms',
      ];

      final seq = PullSequencer.sequence(registered: registered);

      expect(seq.resources, registered);
      expect(seq.fallback, SequenceFallback.noPlan);
      expect(seq.violated, isNull);
    });

    test('plan sans aucun flux : idem, aucune ressource perdue', () {
      const registered = ['enrollment_referential', 'classrooms', 'orphelin'];

      final seq = PullSequencer.sequence(
        registered: registered,
        plan: planOfKeys(const []),
      );

      expect(seq.resources, registered);
      expect(seq.fallback, SequenceFallback.noPlan);
    });
  });

  group('tri topologique', () {
    test('un plan déjà correct ressort inchangé', () {
      final seq = PullSequencer.sequence(
        registered: const ['classrooms', 'classroom_members', 'attendance'],
        plan: planOf([
          (SyncPlanKeys.classroomClassrooms, const []),
          (SyncPlanKeys.classroomMembers, [SyncPlanKeys.classroomClassrooms]),
          (SyncPlanKeys.attendanceRecords, [SyncPlanKeys.classroomMembers]),
        ]),
      );

      expect(seq.resources, const [
        'classrooms',
        'classroom_members',
        'attendance',
      ]);
      expect(seq.fallback, SequenceFallback.none);
      expect(seq.violated, isNull);
    });

    test('un dependsOn réordonne le flux qui dépend, sans toucher aux '
        'autres', () {
      // Reçu dans un ordre que le serveur n'enverrait pas : le membre d'abord,
      // la classe en dernier.
      final seq = PullSequencer.sequence(
        registered: const [
          'classroom_members',
          'classroom_transfers',
          'classrooms',
        ],
        plan: planOf([
          (SyncPlanKeys.classroomMembers, [SyncPlanKeys.classroomClassrooms]),
          (SyncPlanKeys.classroomTransfers, const []),
          (SyncPlanKeys.classroomClassrooms, const []),
        ]),
      );

      expect(seq.resources, const [
        // Départage stable : `transfers` et `classrooms` sont tous deux libres,
        // et le plan les donnait dans cet ordre. Un tri par nom rendrait
        // `classrooms` en premier.
        'classroom_transfers',
        'classrooms',
        'classroom_members',
      ]);
      expect(seq.fallback, SequenceFallback.none);
    });

    test('un flux à deux parents attend les deux', () {
      final seq = PullSequencer.sequence(
        registered: const [
          'academics_cours',
          'academics_grades_referential',
          'classrooms',
        ],
        plan: planOf([
          (
            SyncPlanKeys.academicsCours,
            [
              SyncPlanKeys.academicsGradesReferential,
              SyncPlanKeys.classroomClassrooms,
            ],
          ),
          (SyncPlanKeys.academicsGradesReferential, const []),
          (SyncPlanKeys.classroomClassrooms, const []),
        ]),
      );

      expect(seq.resources.indexOf('academics_cours'), 2);
      expect(seq.fallback, SequenceFallback.none);
    });
  });

  group('cycle', () {
    test('A dépend de B et B de A : repli sur l\'ordre du plan tel que reçu, '
        'sans lever ni boucler', () {
      final seq = PullSequencer.sequence(
        registered: const [
          'attendance',
          'schedule_sessions',
          'schedule_time_slots',
        ],
        plan: planOf([
          (SyncPlanKeys.scheduleSessions, [SyncPlanKeys.scheduleTimeSlots]),
          (SyncPlanKeys.scheduleTimeSlots, [SyncPlanKeys.scheduleSessions]),
          (SyncPlanKeys.attendanceRecords, const []),
        ]),
      );

      expect(seq.fallback, SequenceFallback.cycle);
      expect(seq.violated, isNull);
      // L'ordre du plan, pas celui d'enregistrement, et pas la moitié du
      // graphe que Kahn avait réussi à sortir avant de bloquer.
      expect(seq.resources, const [
        'schedule_sessions',
        'schedule_time_slots',
        'attendance',
      ]);
    });

    test('une clé dupliquée qui déclare une dépendance n\'est PAS un cycle', () {
      // Non-régression : `plan.keys` gardait les deux entrées là où
      // `inDegree`/`dependents` les fusionnent. Kahn sortait donc un sommet de
      // moins que le compte attendu et concluait au cycle sur un graphe
      // parfaitement acyclique. Le repli restait bénin — l'ordre du plan était
      // déjà le bon — mais sous F5 un compteur de cycles aurait menti, sans
      // qu'aucun symptôme ne le trahisse. Le séquenceur dédoublonne désormais
      // avant de trier.
      final seq = PullSequencer.sequence(
        registered: const ['classrooms', 'classroom_members'],
        plan: planOf([
          (SyncPlanKeys.classroomClassrooms, const []),
          (SyncPlanKeys.classroomMembers, [SyncPlanKeys.classroomClassrooms]),
          (SyncPlanKeys.classroomMembers, [SyncPlanKeys.classroomClassrooms]),
        ]),
      );

      expect(
        seq.fallback,
        SequenceFallback.none,
        reason: 'ce plan n\'a aucun cycle',
      );
      // Et la ressource dupliquée n'apparaît qu'une fois dans la séquence.
      expect(seq.resources, const ['classrooms', 'classroom_members']);
    });
  });

  group('les quatre gardes money-grade', () {
    /// Le repli attendu d'une violation : l'ordre d'enregistrement en bloc.
    ///
    /// Volontairement différent de ce qu'une correction partielle produirait —
    /// sinon l'assertion ne distinguerait pas les deux.
    const registered = [
      'enrollment_referential',
      'finance_student_charges',
      'finance_payments',
      'classrooms',
      'academics_grades_referential',
      'academics_cours',
      'academics_evaluations',
    ];

    void expectViolation(PullSequence seq, MoneyGradeEdge edge) {
      expect(seq.fallback, SequenceFallback.moneyGradeViolation);
      expect(seq.violated, same(edge));
      expect(seq.resources, registered, reason: edge.consequence);
    }

    test('créances après paiements : le caissier réencaisse', () {
      final edge = edgeBetween(
        SyncPlanKeys.financeStudentCharges,
        SyncPlanKeys.financePayments,
      );

      final seq = PullSequencer.sequence(
        registered: registered,
        plan: planOfKeys(const [
          SyncPlanKeys.financePayments,
          SyncPlanKeys.financeStudentCharges,
        ]),
      );

      expectViolation(seq, edge);
      expect(edge.consequence, contains('réencaisse'));
    });

    test('classes avant référentiel : les classes échouent en bloc', () {
      final edge = edgeBetween(
        SyncPlanKeys.schoolReferential,
        SyncPlanKeys.classroomClassrooms,
      );

      final seq = PullSequencer.sequence(
        registered: registered,
        plan: planOfKeys(const [
          SyncPlanKeys.classroomClassrooms,
          SyncPlanKeys.schoolReferential,
        ]),
      );

      expectViolation(seq, edge);
    });

    test('cours avant barème : le détail des cours se compose sans barème', () {
      final edge = edgeBetween(
        SyncPlanKeys.academicsGradesReferential,
        SyncPlanKeys.academicsCours,
      );

      final seq = PullSequencer.sequence(
        registered: registered,
        plan: planOfKeys(const [
          SyncPlanKeys.academicsCours,
          SyncPlanKeys.academicsGradesReferential,
        ]),
      );

      expectViolation(seq, edge);
    });

    test('évaluations avant cours : zéro appel réseau, en silence', () {
      final edge = edgeBetween(
        SyncPlanKeys.academicsCours,
        SyncPlanKeys.academicsEvaluations,
      );

      final seq = PullSequencer.sequence(
        registered: registered,
        plan: planOfKeys(const [
          // Le barème est en tête et n'est donc pas, lui, violé : la garde
          // doit continuer à examiner les arêtes suivantes.
          SyncPlanKeys.academicsGradesReferential,
          SyncPlanKeys.academicsEvaluations,
          SyncPlanKeys.academicsCours,
        ]),
      );

      expectViolation(seq, edge);
    });

    test('une dépendance serveur qui inverse la paire Finance est refusée '
        'elle aussi — la garde juge l\'ordre trié, pas l\'ordre reçu', () {
      final edge = edgeBetween(
        SyncPlanKeys.financeStudentCharges,
        SyncPlanKeys.financePayments,
      );

      // Reçu dans le bon ordre : seule la dépendance déclarée l'inverse.
      final seq = PullSequencer.sequence(
        registered: registered,
        plan: planOf([
          (SyncPlanKeys.financeStudentCharges, [SyncPlanKeys.financePayments]),
          (SyncPlanKeys.financePayments, const []),
        ]),
      );

      expectViolation(seq, edge);
    });

    test('une arête dont le flux amont est absent du plan n\'est pas '
        'violée — le comptable garde son cycle', () {
      // Ce compte ne reçoit pas `academics.cours`.
      final seq = PullSequencer.sequence(
        registered: registered,
        plan: planOfKeys(const [
          SyncPlanKeys.financeStudentCharges,
          SyncPlanKeys.financePayments,
          SyncPlanKeys.academicsEvaluations,
        ]),
      );

      expect(seq.fallback, SequenceFallback.none);
      expect(seq.violated, isNull);
      expect(seq.resources.first, 'finance_student_charges');
    });

    test('une arête dont le flux amont est absent du plan n\'est pas violée — '
        'cas du référentiel école', () {
      // Un porteur qui reçoit les classes sans le référentiel : l'arête est
      // sans objet, pas inversée.
      final seq = PullSequencer.sequence(
        registered: registered,
        plan: planOfKeys(const [
          SyncPlanKeys.classroomClassrooms,
          SyncPlanKeys.financeStudentCharges,
          SyncPlanKeys.financePayments,
        ]),
      );

      expect(seq.fallback, SequenceFallback.none);
      expect(seq.violated, isNull);
      expect(seq.resources.first, 'classrooms');
    });
  });

  group('projection clés → ressources', () {
    test('une clé inconnue de l\'alias est sautée sans erreur', () {
      final seq = PullSequencer.sequence(
        registered: const ['classrooms', 'attendance'],
        plan: planOfKeys(const [
          'martien.flux-du-futur',
          SyncPlanKeys.classroomClassrooms,
          SyncPlanKeys.attendanceRecords,
        ]),
      );

      expect(seq.resources, const ['classrooms', 'attendance']);
      expect(seq.fallback, SequenceFallback.none);
    });

    test('une clé dont la ressource n\'est pas enregistrée est sautée', () {
      final seq = PullSequencer.sequence(
        registered: const ['classrooms'],
        plan: planOfKeys(const [
          SyncPlanKeys.disciplineCases,
          SyncPlanKeys.classroomClassrooms,
        ]),
      );

      expect(seq.resources, const ['classrooms']);
      expect(seq.resources, isNot(contains('disciplinary_cases')));
    });

    test('enrollment.snapshots rend ses deux ressources dans l\'ordre de '
        'l\'alias : l\'hydratant puis le delta', () {
      // Enregistrées à l'envers exprès : c'est l'alias qui décide, pas le
      // registre — et le plan, lui, ne dit rien de cet ordre.
      final seq = PullSequencer.sequence(
        registered: const ['enrollments', 'enrollment_snapshots'],
        plan: planOfKeys(const [SyncPlanKeys.enrollmentSnapshots]),
      );

      expect(seq.resources, const ['enrollment_snapshots', 'enrollments']);
    });

    test('une ressource enregistrée qu\'aucune clé ne couvre est ajoutée à la '
        'fin, dans son ordre d\'enregistrement', () {
      final seq = PullSequencer.sequence(
        registered: const [
          'orphelin_a',
          'finance_student_charges',
          'orphelin_b',
        ],
        plan: planOfKeys(const [SyncPlanKeys.financeStudentCharges]),
      );

      expect(seq.resources, const [
        'finance_student_charges',
        'orphelin_a',
        'orphelin_b',
      ]);
    });

    test('aucune ressource n\'apparaît deux fois, même si deux entrées du plan '
        'la réclament', () {
      final seq = PullSequencer.sequence(
        registered: const ['enrollment_snapshots', 'enrollments'],
        plan: planOfKeys(const [
          SyncPlanKeys.enrollmentSnapshots,
          SyncPlanKeys.enrollmentSnapshots,
        ]),
      );

      expect(seq.resources, const ['enrollment_snapshots', 'enrollments']);
      expect(seq.fallback, SequenceFallback.none);
    });
  });

  group('graphe non clos', () {
    test('un dependsOn vers une clé absente du plan est ignoré, pas traité en '
        'erreur', () {
      final seq = PullSequencer.sequence(
        registered: const ['classroom_members', 'attendance'],
        plan: planOf([
          // Le serveur élague `dependsOn` aux clés du plan ; celui-ci ne l'a
          // pas fait. Compter ce parent laisserait `classroom.members` à un
          // degré entrant que rien ne décrémente — donc un faux cycle.
          (SyncPlanKeys.classroomMembers, [SyncPlanKeys.classroomClassrooms]),
          (SyncPlanKeys.attendanceRecords, const []),
        ]),
      );

      expect(seq.fallback, SequenceFallback.none);
      expect(seq.resources, const ['classroom_members', 'attendance']);
    });
  });

  group('test de réalité — le plan complet des dix-huit clés', () {
    /// Le plan tel que le serveur l'envoie à un compte qui a tous les droits :
    /// le référentiel école en tête, la chaîne finance, la chaîne academics.
    final complet = planOf([
      (SyncPlanKeys.schoolReferential, const []),
      (SyncPlanKeys.enrollmentSnapshots, [SyncPlanKeys.schoolReferential]),
      (
        SyncPlanKeys.enrollmentReenrollmentCohort,
        [SyncPlanKeys.enrollmentSnapshots],
      ),
      (SyncPlanKeys.enrollmentPreEnrollments, [SyncPlanKeys.schoolReferential]),
      (SyncPlanKeys.classroomClassrooms, [SyncPlanKeys.schoolReferential]),
      (
        SyncPlanKeys.classroomMembers,
        [SyncPlanKeys.classroomClassrooms, SyncPlanKeys.enrollmentSnapshots],
      ),
      (SyncPlanKeys.classroomTransfers, [SyncPlanKeys.classroomClassrooms]),
      (SyncPlanKeys.financeStudentCharges, [SyncPlanKeys.enrollmentSnapshots]),
      (SyncPlanKeys.financePayments, [SyncPlanKeys.financeStudentCharges]),
      (SyncPlanKeys.attendanceRecords, [SyncPlanKeys.classroomMembers]),
      (SyncPlanKeys.disciplineCases, [SyncPlanKeys.enrollmentSnapshots]),
      (SyncPlanKeys.scheduleTimeSlots, [SyncPlanKeys.schoolReferential]),
      (SyncPlanKeys.scheduleSessions, [SyncPlanKeys.scheduleTimeSlots]),
      (
        SyncPlanKeys.academicsGradesReferential,
        [SyncPlanKeys.schoolReferential],
      ),
      (
        SyncPlanKeys.academicsCours,
        [
          SyncPlanKeys.academicsGradesReferential,
          SyncPlanKeys.classroomClassrooms,
        ],
      ),
      (SyncPlanKeys.academicsEvaluations, [SyncPlanKeys.academicsCours]),
      (SyncPlanKeys.academicsNotes, [SyncPlanKeys.academicsEvaluations]),
      (SyncPlanKeys.editiqueDocuments, [SyncPlanKeys.financePayments]),
    ]);

    /// L'ordre d'enregistrement de la DI, délibérément hostile : la finance et
    /// les cours y précèdent le référentiel. Si la séquence en sort saine,
    /// c'est le plan qui a gouverné, pas le registre.
    const registered = [
      'finance_payments',
      'finance_student_charges',
      'academics_evaluations',
      'academics_cours',
      'academics_notes',
      'academics_grades_referential',
      'classrooms',
      'classroom_members',
      'classroom_transfers',
      'enrollment_referential',
      'enrollment_snapshots',
      'enrollments',
      'enrollment_reenrollment_cohort',
      'enrollment_pre_enrollments',
      'attendance',
      'disciplinary_cases',
      'schedule_time_slots',
      'schedule_sessions',
      'editique_documents',
    ];

    test('la séquence sort du tri topologique, sans repli', () {
      final seq = PullSequencer.sequence(registered: registered, plan: complet);

      expect(seq.fallback, SequenceFallback.none);
      expect(seq.violated, isNull);
    });

    test('les dix-neuf ressources sont couvertes, chacune une fois', () {
      final seq = PullSequencer.sequence(registered: registered, plan: complet);

      expect(seq.resources, hasLength(19));
      expect(seq.resources.toSet(), registered.toSet());
      expect(seq.resources.first, 'enrollment_referential');
    });

    test('aucune des quatre arêtes money-grade n\'est inversée', () {
      final seq = PullSequencer.sequence(registered: registered, plan: complet);

      for (final edge in kMoneyGradeEdges) {
        final amont = resourcesOf(
          edge.before,
        ).map(seq.resources.indexOf).reduce((a, b) => a > b ? a : b);
        final aval = resourcesOf(
          edge.after,
        ).map(seq.resources.indexOf).reduce((a, b) => a < b ? a : b);
        expect(
          amont,
          lessThan(aval),
          reason: '${edge.before} → ${edge.after} : ${edge.consequence}',
        );
      }
    });

    test('l\'hydratant précède le delta, y compris dans le plan complet', () {
      final seq = PullSequencer.sequence(registered: registered, plan: complet);

      expect(
        seq.resources.indexOf('enrollment_snapshots'),
        lessThan(seq.resources.indexOf('enrollments')),
      );
    });
  });
}
