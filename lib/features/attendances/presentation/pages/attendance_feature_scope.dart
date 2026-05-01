import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';

class AttendanceFeatureScope extends StatefulWidget {
  final Widget child;

  const AttendanceFeatureScope({super.key, required this.child});

  @override
  State<AttendanceFeatureScope> createState() => _AttendanceFeatureScopeState();
}

class _AttendanceFeatureScopeState extends State<AttendanceFeatureScope> {
  late final AttendanceBloc _attendanceBloc;
  late final BootstrapCurrentYearBloc _bootstrapCurrentYearBloc;

  @override
  void initState() {
    super.initState();
    _attendanceBloc = GetIt.instance<AttendanceBloc>();
    _bootstrapCurrentYearBloc = GetIt.instance<BootstrapCurrentYearBloc>();
  }

  @override
  void dispose() {
    _attendanceBloc.close();
    _bootstrapCurrentYearBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AttendanceBloc>.value(value: _attendanceBloc),
        BlocProvider<BootstrapCurrentYearBloc>.value(
          value: _bootstrapCurrentYearBloc,
        ),
      ],
      child: widget.child,
    );
  }
}
