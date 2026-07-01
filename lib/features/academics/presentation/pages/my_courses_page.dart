import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/course_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/course_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/course_state.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/my_courses_header.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/my_courses_skeleton.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/my_courses_success_view.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/states/my_courses_results_empty_state.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/states/my_courses_results_error_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';

/// Page « Cours ▸ Mes cours » : liste des cours de l'enseignant connecté,
/// regroupés par classe (accordéons). Lecture seule. Chargement automatique au
/// montage ; états chargement / vide / erreur via les widgets partagés.
class MyCoursesPage extends StatefulWidget {
  /// Ouvre le détail d'un cours (`null` → tuiles non interactives).
  final void Function(CoursDetailArgs args)? onOpenCourse;

  const MyCoursesPage({super.key, this.onOpenCourse});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
  @override
  void initState() {
    super.initState();
    // Charge une seule fois : au retour du détail, le BLoC (vivant dans le
    // scope) est déjà en succès → pas de re-fetch ni de clignotement.
    if (context.read<CourseBloc>().state.status == CourseStatus.initial) {
      context.read<CourseBloc>().add(const MyCoursesRequested());
    }
  }

  Future<void> _contactAdmin() async {
    await launchUrl(Uri(scheme: 'mailto', path: AppConstants.supportEmail));
    if (!mounted) return; // garde mounted après await (règle non-négociable #8)
  }

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      scrollable: true,
      child: BlocBuilder<CourseBloc, CourseState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status ||
            prev.courses != curr.courses ||
            prev.errorType != curr.errorType,
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MyCoursesHeader(),
              const SizedBox(height: AppSpacing.xl),
              AnimatedSize(
                duration: AppMotion.standard,
                curve: AppMotion.outCurve,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: AppMotion.standard,
                  switchInCurve: AppMotion.outCurve,
                  switchOutCurve: AppMotion.inCurve,
                  child: KeyedSubtree(
                    key: ValueKey<String>(
                      '${state.status.name}-${state.errorType.name}',
                    ),
                    child: _buildBody(context, state),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, CourseState state) {
    return switch (state.status) {
      CourseStatus.loading => const MyCoursesSkeleton(),
      CourseStatus.success =>
        state.courses.isEmpty
            ? const MyCoursesResultsEmptyState()
            : MyCoursesSuccessView(
                courses: state.courses,
                onOpenCourse: widget.onOpenCourse,
              ),
      CourseStatus.failure => MyCoursesResultsErrorState(
        type: state.errorType,
        onRetry: () =>
            context.read<CourseBloc>().add(const MyCoursesRequested()),
        onReconnect: () =>
            context.read<AuthBloc>().add(const AuthLogoutRequested()),
        onContactAdmin: _contactAdmin,
      ),
      CourseStatus.initial => const SizedBox.shrink(),
    };
  }
}
