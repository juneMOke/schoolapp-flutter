import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';
import 'package:school_app_flutter/core/navigation/screen_back_scope.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/pages/cours_notation_detail_page.dart';
import 'package:school_app_flutter/features/academics/presentation/pages/my_courses_page.dart';

/// Coordinateur in-shell de la feature Cours : bascule entre la liste « Mes
/// cours » et le détail d'un cours sans quitter le volet (fidèle au `nav({view})`
/// de la spec — sidebar conservée, pas de route GoRouter). Le `CourseBloc` de la
/// liste vit dans le `CoursesFeatureScope` parent ; le détail fournit son propre
/// `CoursNotationBloc`.
class CoursesCoordinatorPage extends StatefulWidget {
  const CoursesCoordinatorPage({super.key});

  @override
  State<CoursesCoordinatorPage> createState() => _CoursesCoordinatorPageState();
}

class _CoursesCoordinatorPageState extends State<CoursesCoordinatorPage> {
  CoursDetailArgs? _openArgs;

  void _openCourse(CoursDetailArgs args) => setState(() => _openArgs = args);

  void _backToList() => setState(() => _openArgs = null);

  /// Retour système : une saisie de notes en cours, plus bas, pose d'abord
  /// la question.
  Future<void> _systemBack() async {
    if (await RouteExitGuard.mayLeave(context) && mounted) _backToList();
  }

  @override
  Widget build(BuildContext context) {
    final open = _openArgs;
    // Retour système : depuis le détail, revenir à la liste (et non à l'Accueil).
    return ScreenBackScope(
      canPop: open == null,
      onBack: _systemBack,
      child: AnimatedSwitcher(
        duration: AppMotion.standard,
        switchInCurve: AppMotion.outCurve,
        switchOutCurve: AppMotion.inCurve,
        child: open == null
            ? MyCoursesPage(
                key: const ValueKey<String>('courses-list'),
                onOpenCourse: _openCourse,
              )
            : CoursNotationDetailPage(
                key: ValueKey<String>('courses-detail-${open.coursId}'),
                args: open,
                onBack: _backToList,
              ),
      ),
    );
  }
}
