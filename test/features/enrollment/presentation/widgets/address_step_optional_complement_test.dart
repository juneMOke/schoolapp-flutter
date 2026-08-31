import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/address_step.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockEnrollmentOfflineBloc
    extends MockBloc<EnrollmentOfflineEvent, EnrollmentOfflineState>
    implements EnrollmentOfflineBloc {}

/// L'adresse complémentaire (rue, avenue, numéro) est **facultative**.
///
/// Elle était exigée comme les quatre champs géographiques : dans les quartiers
/// où rien n'est numéroté, franchir l'étape imposait d'inventer une ligne. Ce
/// qui reste vrai : la ville, le district, la commune et le quartier sont, eux,
/// toujours obligatoires — sans quoi ce test signerait l'abandon de toute
/// validation plutôt que celui d'un seul champ.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockEnrollmentOfflineBloc offline;

  setUp(() {
    offline = _MockEnrollmentOfflineBloc();
    whenListen(
      offline,
      const Stream<EnrollmentOfflineState>.empty(),
      initialState: const EnrollmentOfflineInitial(),
    );
  });

  // Valeurs prises dans `assets/catalogs/address_geo_catalog.json` : le
  // catalogue re-résout ce qu'il reçoit, et une commune inconnue de lui serait
  // effacée au chargement — l'étape deviendrait invalide pour une raison
  // étrangère à ce que le test prouve.
  StudentDetail student({required String address}) => StudentDetail(
    id: 'stu-1',
    firstName: 'Daniel',
    lastName: 'Kabongo',
    surname: 'Mwamba',
    dateOfBirth: '2012-05-04',
    gender: Gender.male,
    birthPlace: 'Kinshasa',
    nationality: 'Congolaise',
    city: 'Kinshasa',
    district: 'Lukunga',
    municipality: 'Barumbu',
    neighborhood: 'Bitshaku-Tshaku',
    address: address,
    schoolLevel: const SchoolLevel(
      id: 'lvl-1',
      name: '6e',
      code: 'L6',
      displayOrder: 1,
      splitIntoClassrooms: false,
    ),
    schoolLevelGroup: const SchoolLevelGroup(
      id: 'grp-1',
      name: 'Secondaire',
      code: 'SEC',
    ),
  );

  Future<void> ouvrir(WidgetTester tester, StudentDetail detail) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<EnrollmentOfflineBloc>.value(
          value: offline,
          child: Scaffold(
            body: SingleChildScrollView(
              child: AddressStep(studentDetail: detail, enrollmentId: 'enr-1'),
            ),
          ),
        ),
      ),
    );
    // Pas de `pumpAndSettle` : tant que le catalogue géographique se charge,
    // la barre de progression indéterminée anime sans fin et la file d'attente
    // ne se vide jamais.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Finder champ(String label) => find.descendant(
    of: find.byWidgetPredicate(
      (widget) => widget is EteeloTextInput && widget.label == label,
    ),
    matching: find.byType(TextField),
  );

  /// « Enregistrer » n'est actif que si l'étape est à la fois modifiée ET
  /// valide : c'est la seule lecture de la validité qu'offre cet écran.
  bool enregistrerActif(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed !=
      null;

  testWidgets('effacer l\'adresse complémentaire laisse l\'étape '
      'enregistrable', (tester) async {
    await ouvrir(tester, student(address: '10, Avenue La source'));

    await tester.enterText(champ('Adresse complémentaire'), '');
    await tester.pump();

    expect(
      enregistrerActif(tester),
      isTrue,
      reason: 'le champ est facultatif : le vider modifie sans invalider',
    );
  });

  testWidgets('le champ ne porte plus d\'étoile d\'obligation', (tester) async {
    await ouvrir(tester, student(address: '10, Avenue La source'));

    final input = tester.widget<EteeloTextInput>(
      find.byWidgetPredicate(
        (widget) =>
            widget is EteeloTextInput &&
            widget.label == 'Adresse complémentaire',
      ),
    );

    expect(input.required, isFalse);
  });

  testWidgets('vidée, elle n\'affiche aucune erreur sous le champ', (
    tester,
  ) async {
    await ouvrir(tester, student(address: '10, Avenue La source'));

    await tester.enterText(champ('Adresse complémentaire'), '');
    await tester.pump();

    // L'écran affiche ses reproches dès qu'il est modifié et invalide : ici il
    // ne l'est plus, donc il n'a rien à reprocher.
    expect(find.textContaining('Adresse complémentaire'), findsOneWidget);
    expect(find.textContaining('obligatoire'), findsNothing);
  });
}
