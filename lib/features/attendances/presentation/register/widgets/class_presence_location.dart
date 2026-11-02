import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/navigation/location_query.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_classroom.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_month_recap.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_cubit.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/helpers/class_picker_options.dart';

/// L'appel d'une classe tenu dans son adresse :
/// `?classe=…&jour=2026-10-09&mois=2026-09&eleve=…&statut=absent&filtre=toWatch`
/// (l'onglet, lui, a son propre lien). F5 rouvre la même classe, le même
/// jour, le même élève, les mêmes filtres.
///
/// Comme la saisie des notes : l'adresse est réécrite SANS entrée
/// d'historique — Précédent quitte l'écran, il ne rejoue pas les jours un à
/// un. Les valeurs par défaut (dernier jour de classe, mois en cours, tous
/// les statuts) laissent l'adresse nue ; la recherche n'y va pas.
class ClassPresenceLocation extends StatefulWidget {
  static const classParam = 'classe';
  static const dayParam = 'jour';
  static const monthParam = 'mois';
  static const studentParam = 'eleve';
  static const statusParam = 'statut';
  static const recapFilterParam = 'filtre';

  static const keys = [
    classParam,
    dayParam,
    monthParam,
    studentParam,
    statusParam,
    recapFilterParam,
  ];

  /// Les classes de l'année : celle de l'adresse s'y retrouve par son
  /// identifiant.
  final List<ClassPickerCycle> cycles;
  final Widget child;

  const ClassPresenceLocation({
    super.key,
    required this.cycles,
    required this.child,
  });

  /// Ce que l'écran met dans l'adresse ; `null` = la valeur par défaut.
  static Map<String, String?> valuesOf(ClassPresenceState state) {
    final classroom = state.classroom;
    if (classroom == null) return {for (final key in keys) key: null};
    final recap = state.recapQuery.filter;
    return {
      classParam: classroom.id,
      dayParam: state.isToday ? null : state.day,
      monthParam: state.isCurrentMonth ? null : state.month,
      studentParam: state.studentId,
      statusParam: state.dayQuery.status?.name,
      recapFilterParam: recap == ClassRecapFilter.all ? null : recap.name,
    };
  }

  @override
  State<ClassPresenceLocation> createState() => _ClassPresenceLocationState();
}

class _ClassPresenceLocationState extends State<ClassPresenceLocation> {
  GoRouter? _router;
  bool _bound = false;

  /// L'adresse d'ouverture, en attente des classes et de l'année.
  Map<String, String?>? _opening;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router = LocationQuery.ownedBy(context);
    if (_bound) return;
    _bound = true;
    final router = _router;
    if (router == null) return;
    final values = {
      for (final key in ClassPresenceLocation.keys)
        key: LocationQuery.read(router, key),
    };
    if (values[ClassPresenceLocation.classParam] != null) _opening = values;
  }

  @override
  Widget build(BuildContext context) {
    if (_opening != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryOpen());
    }
    return BlocListener<ClassPresenceCubit, ClassPresenceState>(
      listenWhen: (previous, current) =>
          previous.academicYearId != current.academicYearId ||
          !_sameAddress(previous, current),
      listener: (context, state) {
        if (_opening != null) {
          _tryOpen();
        } else {
          _write(ClassPresenceLocation.valuesOf(state));
        }
      },
      child: widget.child,
    );
  }

  static bool _sameAddress(ClassPresenceState a, ClassPresenceState b) {
    final left = ClassPresenceLocation.valuesOf(a);
    final right = ClassPresenceLocation.valuesOf(b);
    return left.keys.every((key) => left[key] == right[key]);
  }

  /// Ouvre la classe de l'adresse dès que l'année et la liste des classes
  /// sont là ; une classe que l'année ne porte plus est oubliée.
  void _tryOpen() {
    final opening = _opening;
    if (!mounted || opening == null) return;
    final cubit = context.read<ClassPresenceCubit>();
    if (cubit.state.academicYearId == null || widget.cycles.isEmpty) return;
    _opening = null;
    final classroom = _classroomOf(opening[ClassPresenceLocation.classParam]!);
    if (classroom == null) {
      _write(ClassPresenceLocation.valuesOf(cubit.state));
      return;
    }
    unawaited(
      cubit.openFromAddress(
        classroom,
        day: opening[ClassPresenceLocation.dayParam],
        month: opening[ClassPresenceLocation.monthParam],
        studentId: opening[ClassPresenceLocation.studentParam],
        status: PresenceStatus.values
            .where((s) => s.name == opening[ClassPresenceLocation.statusParam])
            .firstOrNull,
        recapFilter: ClassRecapFilter.values
            .where(
              (f) => f.name == opening[ClassPresenceLocation.recapFilterParam],
            )
            .firstOrNull,
      ),
    );
  }

  ClassPresenceClassroom? _classroomOf(String id) {
    for (final cycle in widget.cycles) {
      for (final level in cycle.levels) {
        for (final classroom in level.classrooms) {
          if (classroom.id == id) return level.classroomOf(classroom);
        }
      }
    }
    return null;
  }

  /// Sans entrée d'historique : Précédent quitte l'écran.
  void _write(Map<String, String?> values) {
    final router = _router;
    if (router == null || !mounted) return;
    Router.neglect(context, () => LocationQuery.write(router, values));
  }
}
