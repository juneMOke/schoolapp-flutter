import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/schedule/presentation/pages/schedule_view.dart';

/// Page « Cours ▸ Emploi du temps » : consultation en **lecture seule** de
/// l'emploi du temps de l'enseignant connecté. La page résout d'abord l'année
/// scolaire courante (`BootstrapCurrentYearBloc`, requise par
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
      final bloc = context.read<BootstrapCurrentYearBloc>();
      if (bloc.state.status == BootstrapContextLoadStatus.initial) {
        bloc.add(
          const BootstrapContextLocalRequested(
            key: AppConstants.bootstrapPayloadKey,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      child: BlocBuilder<BootstrapCurrentYearBloc, BootstrapContextState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status || prev.bootstrap != curr.bootstrap,
        builder: (context, bootstrapState) {
          if (bootstrapState.status == BootstrapContextLoadStatus.loading ||
              bootstrapState.status == BootstrapContextLoadStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          final bootstrap = bootstrapState.bootstrap;
          if (bootstrapState.status != BootstrapContextLoadStatus.success ||
              bootstrap == null ||
              bootstrap.academicYear.id.isEmpty) {
            return BootstrapContextError(
              onLogout: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            );
          }

          return ScheduleView(
            academicYearId: bootstrap.academicYear.id,
            onOpenCourse: widget.onOpenCourse,
          );
        },
      ),
    );
  }
}
