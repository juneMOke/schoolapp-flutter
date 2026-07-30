import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_state.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_organisation_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockClassroomBloc extends MockBloc<ClassroomEvent, ClassroomState>
    implements ClassroomBloc {}

class _MockClassroomOfflineBloc
    extends MockBloc<ClassroomOfflineEvent, ClassroomOfflineState>
    implements ClassroomOfflineBloc {}

class _MockAcademicYearContextBloc
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// Régression : les toasts du TRANSFERT et de l'AFFECTATION ne doivent jamais
/// se déclencher l'un pour l'autre.
///
/// Les deux statuts du `ClassroomOfflineState` sont collants (ils restent
/// `success`/`failure` après le geste). Avec un listener unique abonné aux DEUX
/// statuts, une notification déclenchée par l'un rejouait le bloc terminal de
/// l'autre — et comme `AppSnackBar` fait `hideCurrentSnackBar()` avant
/// d'afficher, le mauvais message *remplaçait* le bon à l'écran.
void main() {
  late _MockClassroomBloc classroomBloc;
  late _MockClassroomOfflineBloc offlineBloc;
  late _MockAcademicYearContextBloc academicYearBloc;
  late _MockAuthBloc authBloc;
  late StreamController<ClassroomOfflineState> offlineStates;

  const assignMessage = 'Élève affecté à la classe.';
  const transferMessage =
      'Transfert enregistré — en attente de synchronisation.';

  setUp(() {
    classroomBloc = _MockClassroomBloc();
    whenListen(
      classroomBloc,
      const Stream<ClassroomState>.empty(),
      initialState: const ClassroomState(),
    );

    offlineStates = StreamController<ClassroomOfflineState>.broadcast();
    offlineBloc = _MockClassroomOfflineBloc();
    whenListen(
      offlineBloc,
      offlineStates.stream,
      initialState: const ClassroomOfflineState(),
    );

    academicYearBloc = _MockAcademicYearContextBloc();
    whenListen(
      academicYearBloc,
      const Stream<AcademicYearContextState>.empty(),
      // Contexte en chargement : le corps de la page ne se monte pas, mais les
      // listeners (au-dessus du BlocBuilder) sont bien actifs — c'est
      // exactement la surface que ce test cible.
      initialState: const AcademicYearContextState(
        status: AcademicYearContextLoadStatus.loading,
      ),
    );

    authBloc = _MockAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(status: AuthStatus.initial),
    );
  });

  tearDown(() => offlineStates.close());

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ClassroomBloc>.value(value: classroomBloc),
            BlocProvider<ClassroomOfflineBloc>.value(value: offlineBloc),
            BlocProvider<AcademicYearContextBloc>.value(
              value: academicYearBloc,
            ),
            BlocProvider<AuthBloc>.value(value: authBloc),
          ],
          child: const Scaffold(body: ClassesOrganisationPage()),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> emit(WidgetTester tester, ClassroomOfflineState state) async {
    offlineStates.add(state);
    await tester.pump();
    // Laisse l'animation d'entrée/sortie du SnackBar se terminer.
    await tester.pump(const Duration(milliseconds: 800));
  }

  /// Purge le SnackBar courant pour ne pas laisser de timer pendant.
  ///
  /// Pas de `pumpAndSettle` ici : le contexte académique est en chargement, donc
  /// un `CircularProgressIndicator` (animation indéterminée perpétuelle) est
  /// monté et empêcherait la convergence. On avance le temps à la main.
  Future<void> drain(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5)); // expiration du SnackBar
    await tester.pump(const Duration(milliseconds: 800)); // animation de sortie
  }

  testWidgets(
    'un transfert réussi n\'affiche PAS le toast d\'affectation resté collé',
    (tester) async {
      await pumpPage(tester);

      // 1) Affectation réussie : son toast s'affiche.
      await emit(
        tester,
        const ClassroomOfflineState(assignStatus: ClassroomStatus.success),
      );
      expect(find.text(assignMessage), findsOneWidget);

      // 2) Transfert enchaîné, `assignStatus` toujours à `success` (collant).
      await emit(
        tester,
        const ClassroomOfflineState(
          assignStatus: ClassroomStatus.success,
          transferStatus: ClassroomStatus.loading,
        ),
      );
      await emit(
        tester,
        const ClassroomOfflineState(
          assignStatus: ClassroomStatus.success,
          transferStatus: ClassroomStatus.success,
        ),
      );

      // Seul le message du geste réellement terminé reste à l'écran.
      expect(find.text(transferMessage), findsOneWidget);
      expect(find.text(assignMessage), findsNothing);

      await drain(tester);
    },
  );

  testWidgets(
    'une affectation réussie n\'affiche PAS le toast de transfert resté collé',
    (tester) async {
      await pumpPage(tester);

      await emit(
        tester,
        const ClassroomOfflineState(transferStatus: ClassroomStatus.success),
      );
      expect(find.text(transferMessage), findsOneWidget);

      await emit(
        tester,
        const ClassroomOfflineState(
          transferStatus: ClassroomStatus.success,
          assignStatus: ClassroomStatus.loading,
        ),
      );
      await emit(
        tester,
        const ClassroomOfflineState(
          transferStatus: ClassroomStatus.success,
          assignStatus: ClassroomStatus.success,
        ),
      );

      expect(find.text(assignMessage), findsOneWidget);
      expect(find.text(transferMessage), findsNothing);

      await drain(tester);
    },
  );

  testWidgets(
    'le passage à `loading` d\'un geste ne réaffiche aucun toast terminal',
    (tester) async {
      await pumpPage(tester);

      await emit(
        tester,
        const ClassroomOfflineState(assignStatus: ClassroomStatus.success),
      );
      await drain(tester);
      expect(find.text(assignMessage), findsNothing); // toast expiré

      // Le seul changement est `transferStatus` → aucun toast ne doit sortir.
      await emit(
        tester,
        const ClassroomOfflineState(
          assignStatus: ClassroomStatus.success,
          transferStatus: ClassroomStatus.loading,
        ),
      );

      expect(find.text(assignMessage), findsNothing);
      expect(find.text(transferMessage), findsNothing);

      await drain(tester);
    },
  );
}
