import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/pages/my_courses_page.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_cubit.dart';
import 'package:school_app_flutter/features/course_programme/presentation/pages/programme_page.dart';

/// Coordinateur in-shell de « Cours ▸ Mes cours » : la pile liste des cours →
/// programme d'un cours → détail d'un chapitre, dans le volet (sidebar
/// conservée, pas de route GoRouter — une route hors coquille donnerait une
/// page nue). Le retour système remonte d'un cran.
///
/// La liste est celle de « Mes évaluations » ([MyCoursesPage], mêmes cartes,
/// même [CourseBloc] fourni par le scope parent) : seule la destination
/// change. Le [ProgrammeCubit] vit au niveau du cours, au-dessus du chapitre :
/// revenir d'un chapitre ne relit pas le programme depuis zéro.
class ProgrammeCoordinatorPage extends StatefulWidget {
  const ProgrammeCoordinatorPage({super.key});

  @override
  State<ProgrammeCoordinatorPage> createState() =>
      _ProgrammeCoordinatorPageState();
}

class _ProgrammeCoordinatorPageState extends State<ProgrammeCoordinatorPage> {
  CoursDetailArgs? _cours;
  Chapitre? _chapitre;

  void _openCours(CoursDetailArgs cours) => setState(() => _cours = cours);

  void _openChapitre(Chapitre chapitre) => setState(() => _chapitre = chapitre);

  void _back() => setState(() {
    if (_chapitre != null) {
      _chapitre = null;
    } else {
      _cours = null;
    }
  });

  @override
  Widget build(BuildContext context) {
    final cours = _cours;
    return PopScope(
      canPop: cours == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AnimatedSwitcher(
        duration: AppMotion.standard,
        switchInCurve: AppMotion.outCurve,
        switchOutCurve: AppMotion.inCurve,
        child: cours == null
            ? MyCoursesPage(
                key: const ValueKey<String>('programme-courses'),
                onOpenCourse: _openCours,
              )
            : BlocProvider<ProgrammeCubit>(
                key: ValueKey<String>('programme-${cours.coursId}'),
                create: (_) =>
                    GetIt.instance<ProgrammeCubit>(param1: cours.coursId)
                      ..load(),
                child: ProgrammePage(
                  cours: cours,
                  onBack: _back,
                  onOpenChapitre: _openChapitre,
                ),
              ),
      ),
    );
  }
}
