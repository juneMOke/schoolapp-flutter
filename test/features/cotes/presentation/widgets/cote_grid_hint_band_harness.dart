import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_save_cubit.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_bulletin_card.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_hint_band.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../bloc/fake_cotes_repository.dart';

const _anglais = CoteCours(
  coursId: 'an',
  branche: 'Anglais',
  maxJournalier: 10,
  maxExamen: 20,
);

/// Deux cours, deux colonnes ouvertes et un examen : les champs, ligne par
/// ligne, sont Français P1, P2, Ex., puis Anglais P1, P2, Ex.
const hintClasse = CoteClasse(
  classroomId: 'c1',
  decoupage: Decoupage.semestre,
  periodes: [
    CotePeriode(
      id: 'S1',
      ordre: 1,
      libelle: 'Semestre 1',
      courant: true,
      locked: false,
      sousPeriodes: [
        CoteSousPeriode(id: 'P1', ordre: 1, locked: false),
        CoteSousPeriode(id: 'P2', ordre: 2, locked: false),
      ],
    ),
  ],
  rubriques: [
    CoteRubrique(id: 'r', cours: [demoFr, _anglais]),
  ],
  eleves: [CoteEleve(studentId: 'e1', lastName: 'Ayaka', firstName: 'Ana')],
);

/// Le bulletin de l'élève e1 dans une page qui défile, un champ hors de la
/// grille au-dessus.
Future<FakeCotesRepository> pumpHintBulletin(
  WidgetTester tester, {
  List<CoteCell> cells = const [],
  CoteClasse classe = hintClasse,
}) async {
  final repository = FakeCotesRepository(classe: classe, cells: cells);
  final bloc = CoteSaisieBloc(repository);
  final save = CoteSaveCubit(repository);
  bloc.add(const CoteSaisieOpened('c1'));
  await tester.runAsync(
    () => bloc.stream.firstWhere((s) => s is CoteSaisieReady),
  );
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: bloc),
        BlocProvider.value(value: save),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('fr'),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(key: outsideFieldKey),
                CoteBulletinCard(classroomName: '7e A'),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  addTearDown(() async {
    await tester.runAsync(() async {
      await save.close();
      await bloc.close();
    });
  });
  return repository;
}

/// Une classe de [count] cours, une seule rubrique : une grille plus haute
/// que l'écran.
CoteClasse longHintClasse(int count) => CoteClasse(
  classroomId: 'c1',
  decoupage: Decoupage.semestre,
  periodes: hintClasse.periodes,
  rubriques: [
    CoteRubrique(
      id: 'r',
      cours: [
        for (var i = 0; i < count; i++)
          CoteCours(
            coursId: 'c$i',
            branche: 'Cours $i',
            maxJournalier: 20,
            maxExamen: 40,
          ),
      ],
    ),
  ],
  eleves: hintClasse.eleves,
);

const outsideFieldKey = Key('outside');

/// Le [index]-ième champ de la grille (le champ d'au-dessus n'en est pas).
Finder gridField(int index) => find
    .descendant(
      of: find.byType(CoteBulletinCard),
      matching: find.byType(TextField),
    )
    .at(index);

/// Le texte de la bande d'aide : vide quand elle n'a rien à dire, ou
/// qu'elle est repliée (aucune case au focus).
String bandText(WidgetTester tester) {
  final text = find.descendant(
    of: find.byType(CoteGridHintBand),
    matching: find.byType(Text),
  );
  if (text.evaluate().isEmpty) return '';
  return tester.widget<Text>(text).textSpan!.toPlainText();
}

/// La surface de la bande, celle que l'œil voit.
Finder get hintPanel => find
    .descendant(
      of: find.byType(CoteGridHintBand),
      matching: find.byType(ExcludeSemantics),
    )
    .first;

Future<void> settleHint(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}
