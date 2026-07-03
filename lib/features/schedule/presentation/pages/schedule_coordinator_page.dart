import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/pages/cours_notation_detail_page.dart';
import 'package:school_app_flutter/features/schedule/presentation/pages/schedule_page.dart';

/// Coordinateur in-shell de l'emploi du temps : bascule entre la grille/vue Jour
/// et le **détail d'un cours** sans quitter le volet (spec §7 — l'action unique
/// est « ouvrir un cours »). Réutilise la page détail « Mes cours »
/// ([CoursNotationDetailPage], qui fournit son propre `CoursNotationBloc`) ; le
/// `TimetableBloc` reste vivant dans le `ScheduleFeatureScope` parent.
class ScheduleCoordinatorPage extends StatefulWidget {
  const ScheduleCoordinatorPage({super.key});

  @override
  State<ScheduleCoordinatorPage> createState() =>
      _ScheduleCoordinatorPageState();
}

class _ScheduleCoordinatorPageState extends State<ScheduleCoordinatorPage> {
  CoursDetailArgs? _openArgs;

  void _openCourse(CoursDetailArgs args) => setState(() => _openArgs = args);

  void _backToTimetable() => setState(() => _openArgs = null);

  @override
  Widget build(BuildContext context) {
    final open = _openArgs;
    return AnimatedSwitcher(
      duration: AppMotion.standard,
      switchInCurve: AppMotion.outCurve,
      switchOutCurve: AppMotion.inCurve,
      child: open == null
          ? SchedulePage(
              key: const ValueKey<String>('schedule-timetable'),
              onOpenCourse: _openCourse,
            )
          : CoursNotationDetailPage(
              key: ValueKey<String>('schedule-course-detail-${open.coursId}'),
              args: open,
              onBack: _backToTimetable,
            ),
    );
  }
}
