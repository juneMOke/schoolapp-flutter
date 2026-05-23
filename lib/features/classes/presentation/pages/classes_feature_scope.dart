import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';

class ClassesFeatureScope extends StatefulWidget {
  final Widget child;

  const ClassesFeatureScope({super.key, required this.child});

  @override
  State<ClassesFeatureScope> createState() => _ClassesFeatureScopeState();
}

class _ClassesFeatureScopeState extends State<ClassesFeatureScope> {
  late final EnrollmentBloc _enrollmentBloc;
  late final BootstrapCurrentYearBloc _bootstrapCurrentYearBloc;
  late final ClassroomBloc _classroomBloc;

  @override
  void initState() {
    super.initState();
    _enrollmentBloc = GetIt.instance<EnrollmentBloc>();
    _bootstrapCurrentYearBloc = GetIt.instance<BootstrapCurrentYearBloc>();
    _classroomBloc = GetIt.instance<ClassroomBloc>();
  }

  @override
  void dispose() {
    _enrollmentBloc.close();
    _bootstrapCurrentYearBloc.close();
    _classroomBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EnrollmentBloc>.value(value: _enrollmentBloc),
        BlocProvider<BootstrapCurrentYearBloc>.value(
          value: _bootstrapCurrentYearBloc,
        ),
        BlocProvider<ClassroomBloc>.value(value: _classroomBloc),
      ],
      child: widget.child,
    );
  }
}
