import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_comment.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/offline_disciplinary_case.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_comments_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockDisciplinaryCaseOfflineBloc
    extends MockBloc<DisciplinaryCaseOfflineEvent, DisciplinaryCaseOfflineState>
    implements DisciplinaryCaseOfflineBloc {}

void main() {
  late MockDisciplinaryCaseOfflineBloc bloc;

  final caseData = OfflineDisciplinaryCase(
    id: 'case-1',
    studentId: 's1',
    studentFirstName: 'Awa',
    studentLastName: 'Diop',
    studentGender: StudentGender.female,
    academicYearId: 'ay1',
    disciplinaryCaseDate: DateTime(2026, 7, 1),
    title: 'Bavardage en classe',
    content: 'Détail du cas',
    category: DisciplinaryCategory.talkingInClass,
    severity: DisciplinarySeverity.minor,
    status: DisciplinaryStatus.open,
    updatedAt: 0,
  );

  setUp(() {
    bloc = MockDisciplinaryCaseOfflineBloc();
    whenListen(
      bloc,
      const Stream<DisciplinaryCaseOfflineState>.empty(),
      initialState: const DisciplinaryOfflineCommentsLoaded('case-1', [
        DisciplinaryComment(
          id: 'c1',
          disciplinaryCaseId: 'case-1',
          content: 'Un commentaire existant',
          authorName: 'M. Traoré',
          createdAt: 0,
          syncState: SyncState.synced,
        ),
      ]),
    );
  });

  Widget harness({EdgeInsets viewInsets = EdgeInsets.zero}) {
    return MaterialApp(
      // AppTheme.light câble le FilledButtonThemeData plein-largeur (CTA) —
      // le laisser par défaut (comme les autres harnesses de dialog) aurait
      // masqué la régression : le bouton "Envoyer", inline dans une Row, doit
      // overrider minimumSize sous peine de largeur infinie (crash layout).
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(viewInsets: viewInsets),
          child: BlocProvider<DisciplinaryCaseOfflineBloc>.value(
            value: bloc,
            child: DisciplinaryCaseCommentsDialog(caseData: caseData),
          ),
        ),
      ),
    );
  }

  testWidgets('rendu sans exception (bouton Envoyer inline dans le champ)', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DisciplinaryCaseCommentsDialog), findsOneWidget);
    expect(find.text('Un commentaire existant'), findsOneWidget);
  });

  // `Dialog` retranche la hauteur du clavier à ce qu'il offre : en paysage il
  // ne reste presque rien, quand les titres, le champ de saisie et le bouton de
  // fermeture en réclament plus de deux cents dp. La modale débordait alors de
  // 189 dp sur 731×411 — et c'est une modale de SAISIE, donc le clavier y est
  // le geste normal.
  testWidgets('paysage, clavier ouvert : rien ne déborde', (tester) async {
    await tester.binding.setSurfaceSize(const Size(731, 411));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      harness(viewInsets: const EdgeInsets.only(bottom: 300)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DisciplinaryCaseCommentsDialog), findsOneWidget);
  });

  // Ne pas déborder ne suffit pas : encore faut-il que le contenu reste
  // ATTEIGNABLE. Sous le seuil, la modale entière défile — et le doigt de
  // l'utilisateur se pose sur la liste, qui couvre presque toute la surface
  // laissée libre par le clavier.
  //
  // La liste doit donc être inerte (`NeverScrollableScrollPhysics`). Maîtresse
  // de son défilement, elle gagnait l'arène des gestes sans avoir rien à faire
  // défiler — hauteur libre ⇒ `maxScrollExtent` nul — et le contenu ne bougeait
  // pas d'un pixel : ni le champ de saisie ni le bouton de fermeture n'étaient
  // accessibles.
  testWidgets('paysage, clavier ouvert : un geste sur la liste fait bien '
      'défiler la modale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(731, 411));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      harness(viewInsets: const EdgeInsets.only(bottom: 300)),
    );
    await tester.pumpAndSettle();

    final defilement = find.byType(SingleChildScrollView);
    expect(defilement, findsOneWidget);

    final avant = tester.getTopLeft(find.text('Bavardage en classe')).dy;
    // Le doigt se pose au milieu de la bande visible, donc sur la liste.
    await tester.dragFrom(
      tester.getRect(defilement).center,
      const Offset(0, -120),
    );
    await tester.pump();
    final apres = tester.getTopLeft(find.text('Bavardage en classe')).dy;

    expect(
      avant - apres,
      greaterThan(0),
      reason: 'la liste ne doit pas confisquer le geste de défilement',
    );
  });
}
