import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_class_visual.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// Le professeur affecté : lit et écrit le programme.
const List<String> kProgrammeTeacher = [
  'academics.course.read',
  'academics.programme.write',
];

/// La direction : lit seulement.
const List<String> kProgrammeReader = ['academics.course.read'];

final CoursDetailArgs kMathsCours = CoursDetailArgs(
  coursId: 'c-1',
  brancheNom: 'Mathématiques',
  classroomName: '7e A',
  visual: AcademicsClassVisual.forIndex(0),
);

/// Monte [child] dans une application française, sous un [AuthBloc] qui porte
/// [permissions].
Widget programmeHost(
  Widget child, {
  List<String> permissions = kProgrammeTeacher,
}) {
  final authBloc = _MockAuthBloc();
  final authState = AuthState(
    status: AuthStatus.authenticated,
    permissions: permissions,
  );
  when(() => authBloc.state).thenReturn(authState);
  whenListen(
    authBloc,
    Stream<AuthState>.value(authState),
    initialState: authState,
  );
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: Scaffold(body: child),
    ),
  );
}
