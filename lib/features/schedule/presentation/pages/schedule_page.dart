import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/schedule/presentation/pages/schedule_view.dart';

/// Page « Cours ▸ Emploi du temps » : consultation en **lecture seule** de
/// l'emploi du temps de l'enseignant connecté. La page résout d'abord l'année
/// scolaire courante (`AcademicYearContextBloc`, requise par
/// `TimetableRequested`), puis délègue le rendu à [ScheduleView].
class SchedulePage extends StatefulWidget {
  /// Ouvre le détail d'un cours (`null` → séances non interactives).
  final void Function(CoursDetailArgs args)? onOpenCourse;

  const SchedulePage({super.key, this.onOpenCourse});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final bloc = context.read<AcademicYearContextBloc>();
      if (bloc.state.status == AcademicYearContextLoadStatus.initial) {
        bloc.add(const AcademicYearContextRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      child: BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status || prev.context != curr.context,
        builder: (context, academicYearState) {
          if (academicYearState.status ==
                  AcademicYearContextLoadStatus.loading ||
              academicYearState.status ==
                  AcademicYearContextLoadStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          final academicYearContext = academicYearState.context;
          if (academicYearState.status !=
                  AcademicYearContextLoadStatus.success ||
              academicYearContext == null ||
              academicYearContext.academicYear.id.isEmpty) {
            return BootstrapContextError(
              onLogout: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            );
          }

          return ScheduleView(
            academicYearId: academicYearContext.academicYear.id,
            onOpenCourse: widget.onOpenCourse,
          );
        },
      ),
    );
  }
}
