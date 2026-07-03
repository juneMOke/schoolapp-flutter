import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_state.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/saisie_draft_controller.dart';

/// Construit une ligne de grille persistée (identité + note éventuelle).
NoteEleveRow row(String id, {StatutNote? statut, double? points}) =>
    NoteEleveRow(
      note: NoteEleve(
        studentId: id,
        firstName: 'F$id',
        lastName: 'L$id',
        pointsObtenus: points,
        statut: statut,
      ),
    );

void main() {
  group('SaisieDraftController — parsing statique', () {
    test('parseNote accepte virgule et point, rejette le vide/invalide', () {
      expect(SaisieDraftController.parseNote('7,5'), 7.5);
      expect(SaisieDraftController.parseNote('7.5'), 7.5);
      expect(SaisieDraftController.parseNote(' 10 '), 10);
      expect(SaisieDraftController.parseNote(''), isNull);
      expect(SaisieDraftController.parseNote('abc'), isNull);
    });

    test(
      'formatNoteRaw retire les décimales superflues et met une virgule',
      () {
        expect(SaisieDraftController.formatNoteRaw(10), '10');
        expect(SaisieDraftController.formatNoteRaw(7.5), '7,5');
        expect(SaisieDraftController.formatNoteRaw(12.25), '12,25');
      },
    );
  });

  group('SaisieDraftController — initialisation depuis la grille', () {
    late SaisieDraftController c;
    setUp(() {
      c = SaisieDraftController()
        ..initialize([
          row('s1', statut: StatutNote.notee, points: 7.5),
          row('s2'), // statut null = pas encore saisi
          row('s3', statut: StatutNote.absentJustifie),
          row('s4', statut: StatutNote.absentNonJustifie),
        ], 10);
    });

    test('ordre, total et statuts dérivés reflètent le persisté', () {
      expect(c.total, 4);
      expect(c.order, ['s1', 's2', 's3', 's4']);
      expect(c.statutFor('s1'), StatutNote.notee);
      expect(c.pointsFor('s1'), 7.5);
      expect(c.rawOf('s1'), '7,5');
      expect(c.statutFor('s2'), StatutNote.enAttente);
      expect(c.statutFor('s3'), StatutNote.absentJustifie);
      expect(c.statutFor('s4'), StatutNote.absentNonJustifie);
    });

    test('à l\'initialisation, rien n\'est « dirty » ni en erreur', () {
      expect(c.dirty, isFalse);
      expect(c.errorCount, 0);
      expect(c.savableDirtyIds, isEmpty);
    });

    test('compteurs par statut', () {
      expect(c.countOf(StatutNote.notee), 1);
      expect(c.countOf(StatutNote.enAttente), 1);
      expect(c.countOf(StatutNote.absentJustifie), 1);
      expect(c.countOf(StatutNote.absentNonJustifie), 1);
      expect(c.enteredCount, 3); // notée + 2 absences
      expect(c.enAttenteCount, 1);
    });
  });

  group('SaisieDraftController — saisie & dérivations', () {
    late SaisieDraftController c;
    setUp(() {
      c = SaisieDraftController()..initialize([row('s1'), row('s2')], 10);
    });

    test('saisie valide → NOTEE + points + dirty', () {
      c.setRaw('s1', '7,5');
      expect(c.statutFor('s1'), StatutNote.notee);
      expect(c.pointsFor('s1'), 7.5);
      expect(c.hasErrorFor('s1'), isFalse);
      expect(c.isDirtyFor('s1'), isTrue);
      expect(c.dirty, isTrue);
      expect(c.savableDirtyIds, ['s1']);
    });

    test(
      'saisie hors bornes → erreur, statut EN_ATTENTE, non enregistrable',
      () {
        c.setRaw('s1', '15');
        expect(c.hasErrorFor('s1'), isTrue);
        expect(c.statutFor('s1'), StatutNote.enAttente);
        expect(c.pointsFor('s1'), isNull);
        expect(c.errorCount, 1);
        // Un champ en erreur n'est jamais poussé à l'enregistrement.
        expect(c.savableDirtyIds, isEmpty);
      },
    );

    test(
      'choisir une absence efface les points ; re-cliquer désélectionne',
      () {
        c.setRaw('s1', '8');
        c.toggleAbsence('s1', StatutNote.absentJustifie);
        expect(c.statutFor('s1'), StatutNote.absentJustifie);
        expect(c.rawOf('s1'), ''); // points effacés (invariant 4)
        // Re-cliquer le même bouton → retour à EN_ATTENTE.
        c.toggleAbsence('s1', StatutNote.absentJustifie);
        expect(c.statutFor('s1'), StatutNote.enAttente);
      },
    );

    test('saisir une note après une absence désélectionne l\'absence', () {
      c.toggleAbsence('s1', StatutNote.absentNonJustifie);
      c.setRaw('s1', '6');
      expect(c.absenceOf('s1'), isNull);
      expect(c.statutFor('s1'), StatutNote.notee);
    });

    test('clearEntry remet la ligne en attente', () {
      c.setRaw('s1', '9');
      c.clearEntry('s1');
      expect(c.statutFor('s1'), StatutNote.enAttente);
      expect(c.rawOf('s1'), '');
    });
  });

  group('SaisieDraftController — pavé numérique (Focus)', () {
    late SaisieDraftController c;
    setUp(() {
      c = SaisieDraftController()..initialize([row('s1')], 10);
    });

    test('virgule jamais en tête, une seule virgule, max 5 caractères', () {
      c.appendNoteChar('s1', ','); // ignoré : jamais en tête
      expect(c.rawOf('s1'), '');
      c.appendNoteChar('s1', '7');
      c.appendNoteChar('s1', ',');
      c.appendNoteChar('s1', ','); // ignoré : déjà une virgule
      c.appendNoteChar('s1', '5');
      expect(c.rawOf('s1'), '7,5');
      c.appendNoteChar('s1', '5');
      c.appendNoteChar('s1', '5'); // '7,555' = 5 caractères
      expect(c.rawOf('s1'), '7,555');
      c.appendNoteChar('s1', '9'); // ignoré : max 5
      expect(c.rawOf('s1'), '7,555');
    });

    test('backspace retire le dernier caractère', () {
      c
        ..appendNoteChar('s1', '8')
        ..appendNoteChar('s1', ',')
        ..appendNoteChar('s1', '5');
      c.backspaceNote('s1');
      expect(c.rawOf('s1'), '8,');
    });

    test('une absence bloque la saisie au pavé', () {
      c.toggleAbsence('s1', StatutNote.absentJustifie);
      c.appendNoteChar('s1', '5');
      expect(c.rawOf('s1'), '');
      expect(c.statutFor('s1'), StatutNote.absentJustifie);
    });
  });

  group('SaisieDraftController — commitSaved', () {
    test(
      'recale la baseline des lignes réussies, garde les échecs « dirty »',
      () {
        final c = SaisieDraftController()
          ..initialize([row('s1'), row('s2')], 10);
        c.setRaw('s1', '8');
        c.setRaw('s2', '9');
        expect(c.savableDirtyIds, ['s1', 's2']);

        // s1 enregistrée (note persistée renvoyée), s2 en échec (inchangée).
        final rowsApresSave = [
          row('s1', statut: StatutNote.notee, points: 8),
          row('s2'),
        ];
        c.commitSaved(['s1'], rowsApresSave);

        expect(c.isDirtyFor('s1'), isFalse); // recalée
        expect(c.isDirtyFor('s2'), isTrue); // reste à réessayer
        expect(c.dirty, isTrue);
        expect(c.savableDirtyIds, ['s2']);
      },
    );
  });

  test('notifie ses écouteurs à chaque mutation', () {
    final c = SaisieDraftController()..initialize([row('s1')], 10);
    var notified = 0;
    c.addListener(() => notified++);
    c.setRaw('s1', '7');
    c.toggleAbsence('s1', StatutNote.absentJustifie);
    c.clearEntry('s1');
    expect(notified, 3);
  });
}
