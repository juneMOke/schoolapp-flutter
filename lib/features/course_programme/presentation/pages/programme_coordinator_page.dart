import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/pages/cours_notation_detail_page.dart';
import 'package:school_app_flutter/features/academics/presentation/pages/my_courses_page.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/chapitre_cubit.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_cubit.dart';
import 'package:school_app_flutter/features/course_programme/presentation/pages/chapitre_detail_page.dart';
import 'package:school_app_flutter/features/course_programme/presentation/pages/programme_page.dart';

/// Ce que montre le coordinateur, du plus large au plus précis.
enum _View { courses, programme, chapitre, evaluations }

/// Coordinateur in-shell de « Cours ▸ Mes cours » : la pile liste des cours →
/// programme d'un cours → détail d'un chapitre, dans le volet (sidebar
/// conservée, pas de route GoRouter — une route hors coquille donnerait une
/// page nue). Le retour système remonte d'un cran.
///
/// La liste est celle de « Mes évaluations » ([MyCoursesPage], mêmes cartes,
/// même `CourseBloc` fourni par le scope parent) : seule la destination
/// change. « Évaluations liées » ouvre le cours tel que « Mes évaluations » le
/// montre ([CoursNotationDetailPage]), un cran au-dessus du chapitre.
///
/// Le [ProgrammeCubit] vit au niveau du cours, au-dessus du chapitre :
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
  bool _evaluations = false;

  _View get _view => switch ((_cours, _chapitre, _evaluations)) {
    (null, _, _) => _View.courses,
    (_, _, true) => _View.evaluations,
    (_, null, _) => _View.programme,
    _ => _View.chapitre,
  };

  void _back() => setState(() {
    switch (_view) {
      case _View.evaluations:
        _evaluations = false;
      case _View.chapitre:
        _chapitre = null;
      case _View.programme:
        _cours = null;
      case _View.courses:
        break;
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
                onOpenCourse: (args) => setState(() => _cours = args),
              )
            : BlocProvider<ProgrammeCubit>(
                key: ValueKey<String>('programme-${cours.coursId}'),
                create: (_) =>
                    GetIt.instance<ProgrammeCubit>(param1: cours.coursId)
                      ..load(),
                child: _CourseStack(
                  cours: cours,
                  view: _view,
                  chapitre: _chapitre,
                  onOpenChapitre: (chapitre) =>
                      setState(() => _chapitre = chapitre),
                  onOpenEvaluations: () => setState(() => _evaluations = true),
                  onBack: _back,
                ),
              ),
      ),
    );
  }
}

/// Le cours ouvert : son programme, un chapitre, ou ses évaluations — sous le
/// même [ProgrammeCubit].
class _CourseStack extends StatelessWidget {
  final CoursDetailArgs cours;
  final _View view;
  final Chapitre? chapitre;
  final ValueChanged<Chapitre> onOpenChapitre;
  final VoidCallback onOpenEvaluations;
  final VoidCallback onBack;

  const _CourseStack({
    required this.cours,
    required this.view,
    required this.chapitre,
    required this.onOpenChapitre,
    required this.onOpenEvaluations,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final programme = context.read<ProgrammeCubit>();
    final chapitre = this.chapitre;
    return AnimatedSwitcher(
      duration: AppMotion.standard,
      switchInCurve: AppMotion.outCurve,
      switchOutCurve: AppMotion.inCurve,
      child: switch (view) {
        _View.evaluations => CoursNotationDetailPage(
          key: ValueKey<String>('programme-evaluations-${cours.coursId}'),
          args: cours,
          onBack: onBack,
        ),
        _View.chapitre when chapitre != null => BlocProvider<ChapitreCubit>(
          key: ValueKey<String>('chapitre-${chapitre.id}'),
          create: (_) =>
              GetIt.instance<ChapitreCubit>(param1: chapitre.id)..load(),
          child: ChapitreDetailPage(
            cours: cours,
            titre: chapitre.titre,
            sousPeriodes: programme.state.sousPeriodes,
            onOpenEvaluations: onOpenEvaluations,
            onBack: () {
              programme.refresh();
              onBack();
            },
          ),
        ),
        _ => ProgrammePage(
          key: ValueKey<String>('programme-page-${cours.coursId}'),
          cours: cours,
          onBack: onBack,
          onOpenChapitre: onOpenChapitre,
        ),
      },
    );
  }
}
