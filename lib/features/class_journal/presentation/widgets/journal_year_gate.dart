import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/states/journal_states.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';

/// Résout l'année scolaire courante (bornes de la navigation, N° de page),
/// appelle [onReady] une seule fois, puis montre [child]. Squelette pendant
/// la résolution ; une année introuvable propose de se reconnecter.
class JournalYearGate extends StatefulWidget {
  final ValueChanged<AcademicYear> onReady;
  final Widget child;

  const JournalYearGate({
    super.key,
    required this.onReady,
    required this.child,
  });

  @override
  State<JournalYearGate> createState() => _JournalYearGateState();
}

class _JournalYearGateState extends State<JournalYearGate> {
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
    widget.onReady(state.context!.academicYear);
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<AcademicYearContextBloc, AcademicYearContextState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status || prev.context != curr.context,
        listener: (context, state) => _startIfReady(state),
        buildWhen: (prev, curr) =>
            prev.status != curr.status || prev.context != curr.context,
        builder: (context, state) => switch (state.status) {
          AcademicYearContextLoadStatus.initial ||
          AcademicYearContextLoadStatus.loading => const JournalSkeleton(),
          AcademicYearContextLoadStatus.success when _hasYear(state) =>
            widget.child,
          AcademicYearContextLoadStatus.success ||
          AcademicYearContextLoadStatus.failure => BootstrapContextError(
            onLogout: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        },
      );
}
