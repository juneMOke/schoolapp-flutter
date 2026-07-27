import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_stats_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';

class ClassesFeatureScope extends StatefulWidget {
  final Widget child;

  const ClassesFeatureScope({super.key, required this.child});

  @override
  State<ClassesFeatureScope> createState() => _ClassesFeatureScopeState();
}

class _ClassesFeatureScopeState extends State<ClassesFeatureScope> {
  late final EnrollmentBloc _enrollmentBloc;
  late final AcademicYearContextBloc _academicYearContextBloc;
  late final ClassroomBloc _classroomBloc;
  late final ClassroomStatsBloc _classroomStatsBloc;
  late final ClassroomOfflineBloc _classroomOfflineBloc;

  @override
  void initState() {
    super.initState();
    _enrollmentBloc = GetIt.instance<EnrollmentBloc>();
    _academicYearContextBloc = GetIt.instance<AcademicYearContextBloc>();
    _classroomBloc = GetIt.instance<ClassroomBloc>();
    _classroomStatsBloc = GetIt.instance<ClassroomStatsBloc>();
    _classroomOfflineBloc = GetIt.instance<ClassroomOfflineBloc>();
  }

  @override
  void dispose() {
    _enrollmentBloc.close();
    _academicYearContextBloc.close();
    _classroomBloc.close();
    _classroomStatsBloc.close();
    _classroomOfflineBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EnrollmentBloc>.value(value: _enrollmentBloc),
        BlocProvider<AcademicYearContextBloc>.value(
          value: _academicYearContextBloc,
        ),
        BlocProvider<ClassroomBloc>.value(value: _classroomBloc),
        BlocProvider<ClassroomStatsBloc>.value(value: _classroomStatsBloc),
        BlocProvider<ClassroomOfflineBloc>.value(value: _classroomOfflineBloc),
      ],
      child: widget.child,
    );
  }
}
