import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/intitule_colonne.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_columns.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_labels.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

CoteClasse _classe({
  required ColonneExamen examen,
  IntituleColonne? Function(int rang)? intitule,
}) => CoteClasse(
  classroomId: 'c',
  decoupage: Decoupage.semestre,
  periodes: [
    for (final ordre in [1, 2])
      CotePeriode(
        id: 'S$ordre',
        ordre: ordre,
        libelle: 'Semestre $ordre',
        courant: ordre == 1,
        locked: false,
        examen: examen,
        sousPeriodes: [
          for (final position in [1, 2])
            CoteSousPeriode(
              id: 'S$ordre-$position',
              ordre: position,
              locked: false,
              intitule: intitule?.call((ordre - 1) * 2 + position),
            ),
        ],
      ),
  ],
  rubriques: const [],
  eleves: const [],
);

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  test('un serveur ancien : les intitulés d\'avant', () {
    final classe = _classe(examen: const ColonneExamen.inconnue());
    final columns = yearColumns(classe);
    final p3 = columns.firstWhere((c) => c.id == 'S2-1');
    final exam = columns.firstWhere((c) => c.id == 'S2');

    expect(CoteLabels.columnShort(l10n, classe.decoupage, p3), 'P3');
    expect(CoteLabels.columnLong(l10n, classe, p3), '3e période');
    expect(CoteLabels.columnShort(l10n, classe.decoupage, exam), 'Exam.');
    expect(CoteLabels.columnChip(l10n, classe.decoupage, exam), 'Examen S2');
    expect(CoteLabels.examLegend(l10n, columns), 'Examen');
  });

  test('les noms de la grille, tels quels', () {
    final classe = _classe(
      examen: const ColonneExamen.nommee(
        IntituleColonne(libelle: 'Composition', libelleCourt: 'Compo.'),
      ),
      intitule: (rang) =>
          IntituleColonne(libelle: 'Étape $rang', libelleCourt: 'É$rang'),
    );
    final columns = yearColumns(classe);
    final e3 = columns.firstWhere((c) => c.id == 'S2-1');
    final exam = columns.firstWhere((c) => c.id == 'S2');

    expect(CoteLabels.columnShort(l10n, classe.decoupage, e3), 'É3');
    expect(CoteLabels.columnLong(l10n, classe, e3), 'Étape 3');
    expect(CoteLabels.columnShort(l10n, classe.decoupage, exam), 'Compo.');
    expect(
      CoteLabels.columnChip(l10n, classe.decoupage, exam),
      'Composition S2',
    );
    expect(
      CoteLabels.columnLong(l10n, classe, exam),
      'Composition · Semestre 2',
    );
    expect(CoteLabels.maxShort(l10n, classe.decoupage, exam), 'Max Compo.');
    expect(CoteLabels.examLegend(l10n, columns), 'Composition');
  });

  test('sans examen : aucune colonne ni maximum d\'examen', () {
    final classe = _classe(examen: const ColonneExamen.absente());
    final columns = yearColumns(classe);

    expect(columns.where((c) => c.kind == CoteColumnKind.examen), isEmpty);
  });
}
