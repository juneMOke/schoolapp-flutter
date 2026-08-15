import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/sync_attendance_pull_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_bloc.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/sync_classroom_referential_use_case.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';

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
  late final AcademicYearContextBloc _academicYearContextBloc;
  late final ClassroomOfflineBloc _classroomOfflineBloc;

  @override
  void initState() {
    super.initState();
    _attendanceBloc = GetIt.instance<AttendanceBloc>();
    _disciplinaryCaseBloc = GetIt.instance<DisciplinaryCaseBloc>();
    _attendanceOfflineBloc = GetIt.instance<AttendanceOfflineBloc>();
    _disciplinaryCaseOfflineBloc =
        GetIt.instance<DisciplinaryCaseOfflineBloc>();
    _academicYearContextBloc = GetIt.instance<AcademicYearContextBloc>();
    // Classes/effectifs pour le dropdown de recherche (CF3, lecture locale) —
    // instance dédiée à cette feature scope, indépendante de celle de Classe.
    _classroomOfflineBloc = GetIt.instance<ClassroomOfflineBloc>();

    // Hydratation best-effort au montage (avant de partir appeler hors-ligne).
    // Le second déclencheur (retour online) passe par le PullCoordinator. Le
    // pull ne lève jamais et l'UI lit TOUJOURS le local : on l'oublie sciemment.
    unawaited(GetIt.instance<SyncAttendancePullUseCase>().call());
    // Le référentiel Classe (classes + roster + transferts) est un PRÉ-REQUIS
    // de ce module, pas une affinité : la feuille d'appel est pilotée par le
    // roster, et le résumé d'assiduité de la fiche élève refuse tout affichage
    // tant que le marqueur de bootstrap des transferts n'est pas posé. Aucun
    // autre déclencheur de montage ne les tirait : sur une tablette démarrée
    // déjà connectée, l'onglet Présence restait à vie sur « Synchronisation en
    // attente » (ADR-015 §6-D).
    unawaited(GetIt.instance<SyncClassroomReferentialUseCase>().call());
  }

  @override
  void dispose() {
    _attendanceBloc.close();
    _disciplinaryCaseBloc.close();
    _attendanceOfflineBloc.close();
    _disciplinaryCaseOfflineBloc.close();
    _academicYearContextBloc.close();
    _classroomOfflineBloc.close();
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
        BlocProvider<AcademicYearContextBloc>.value(
          value: _academicYearContextBloc,
        ),
        BlocProvider<ClassroomOfflineBloc>.value(value: _classroomOfflineBloc),
      ],
      child: widget.child,
    );
  }
}
