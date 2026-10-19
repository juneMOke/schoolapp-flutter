import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/home/presentation/pages/home_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// Tous les droits déclarés : ces tests portent sur la structure de la coquille
/// (sidebar ancrée, tiroir, hamburger), pas sur le filtrage — couvert par
/// `module_access_registry_test.dart`. Sans droits, l'arborescence se réduirait
/// à l'Accueil et il n'y aurait plus de menu à replier.
const _tousDroits = <String>[
  'enrollment.read',
  'enrollment.stats.read',
  'finance.charge.read',
  'finance.stats.read',
  'classroom.read',
  'classroom.stats.read',
  'attendance.read',
  'attendance.stats.read',
  'discipline.read',
  'academics.course.read',
  'academics.result.read',
  'schedule.read',
  'editique.read',
];

/// La coquille montée telle qu'en production, ouverte sur [subMenuId].
///
/// La barre supérieure monte la pastille de synchro globale
/// (`BlocBuilder<SyncStatusCubit>`) fournie à la racine en production ; ici un
/// cubit mocké figé sur « synced ». L'`AuthBloc` est requis depuis ADR-014 :
/// la coquille construit son arborescence sur ses permissions.
Widget buildShellHarness({String? subMenuId}) {
  final syncStatusCubit = _MockSyncStatusCubit();
  whenListen(
    syncStatusCubit,
    const Stream<SyncStatusState>.empty(),
    initialState: const SyncStatusState(status: SyncStatus.synced),
  );

  final authBloc = _MockAuthBloc();
  const authState = AuthState(
    status: AuthStatus.authenticated,
    permissions: _tousDroits,
  );
  when(() => authBloc.state).thenReturn(authState);
  whenListen(
    authBloc,
    const Stream<AuthState>.empty(),
    initialState: authState,
  );

  return MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<SyncStatusCubit>.value(value: syncStatusCubit),
        BlocProvider<AuthBloc>.value(value: authBloc),
      ],
      child: HomePage(subMenuId: subMenuId),
    ),
  );
}
