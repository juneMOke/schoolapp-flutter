import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/sync_attendance_pull_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';

class AttendanceFeatureScope extends StatefulWidget {
  final Widget child;

  const AttendanceFeatureScope({super.key, required this.child});

  @override
  State<AttendanceFeatureScope> createState() => _AttendanceFeatureScopeState();
}

class _AttendanceFeatureScopeState extends State<AttendanceFeatureScope> {
  late final AttendanceBloc _attendanceBloc;
  late final DisciplinaryCaseBloc _disciplinaryCaseBloc;
  late final AttendanceOfflineBloc _attendanceOfflineBloc;
  late final DisciplinaryCaseOfflineBloc _disciplinaryCaseOfflineBloc;
  late final BootstrapCurrentYearBloc _bootstrapCurrentYearBloc;

  @override
  void initState() {
    super.initState();
    _attendanceBloc = GetIt.instance<AttendanceBloc>();
    _disciplinaryCaseBloc = GetIt.instance<DisciplinaryCaseBloc>();
    _attendanceOfflineBloc = GetIt.instance<AttendanceOfflineBloc>();
    _disciplinaryCaseOfflineBloc =
        GetIt.instance<DisciplinaryCaseOfflineBloc>();
    _bootstrapCurrentYearBloc = GetIt.instance<BootstrapCurrentYearBloc>();

    // Hydratation best-effort au montage (avant de partir appeler hors-ligne).
    // Le second déclencheur (retour online) passe par le PullCoordinator. Le
    // pull ne lève jamais et l'UI lit TOUJOURS le local : on l'oublie sciemment.
    unawaited(GetIt.instance<SyncAttendancePullUseCase>().call());
  }

  @override
  void dispose() {
    _attendanceBloc.close();
    _disciplinaryCaseBloc.close();
    _attendanceOfflineBloc.close();
    _disciplinaryCaseOfflineBloc.close();
    _bootstrapCurrentYearBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AttendanceBloc>.value(value: _attendanceBloc),
        BlocProvider<DisciplinaryCaseBloc>.value(value: _disciplinaryCaseBloc),
        BlocProvider<AttendanceOfflineBloc>.value(
          value: _attendanceOfflineBloc,
        ),
        BlocProvider<DisciplinaryCaseOfflineBloc>.value(
          value: _disciplinaryCaseOfflineBloc,
        ),
        BlocProvider<BootstrapCurrentYearBloc>.value(
          value: _bootstrapCurrentYearBloc,
        ),
      ],
      child: widget.child,
    );
  }
}
