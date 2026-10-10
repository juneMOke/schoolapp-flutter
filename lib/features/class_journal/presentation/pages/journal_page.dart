import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_day_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/journal_view.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/states/journal_states.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';

/// « Cours ▸ Mon journal » : le journal de classe journalier du professeur.
/// La page résout d'abord l'année scolaire courante (bornes de la navigation,
/// N° de page), puis ouvre le journal sur aujourd'hui.
class JournalPage extends StatefulWidget {
  /// Ouvre la saisie d'une séance ; `null` : lecture seule.
  final ValueChanged<JournalLine>? onOpen;

  const JournalPage({super.key, this.onOpen});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  var _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<AcademicYearContextBloc>();
      if (bloc.state.status == AcademicYearContextLoadStatus.initial) {
        bloc.add(const AcademicYearContextRequested());
      }
      _startIfReady(bloc.state);
    });
  }

  static bool _hasYear(AcademicYearContextState state) =>
      state.status == AcademicYearContextLoadStatus.success &&
      (state.context?.academicYear.id.isNotEmpty ?? false);

  void _startIfReady(AcademicYearContextState state) {
    if (_started || !_hasYear(state)) return;
    _started = true;
    context.read<JournalDayCubit>().start(state.context!.academicYear);
  }

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      scrollable: true,
      child: BlocConsumer<AcademicYearContextBloc, AcademicYearContextState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status || prev.context != curr.context,
        listener: (context, state) => _startIfReady(state),
        buildWhen: (prev, curr) =>
            prev.status != curr.status || prev.context != curr.context,
        builder: (context, state) => switch (state.status) {
          AcademicYearContextLoadStatus.initial ||
          AcademicYearContextLoadStatus.loading => const JournalSkeleton(),
          AcademicYearContextLoadStatus.success when _hasYear(state) =>
            JournalView(onOpen: widget.onOpen),
          AcademicYearContextLoadStatus.success ||
          AcademicYearContextLoadStatus.failure => BootstrapContextError(
            onLogout: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        },
      ),
    );
  }
}
