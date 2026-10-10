import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_day_cubit.dart';

/// Scope du journal de classe (cf. AGENTS.md §11 — FeatureScope) : fournit le
/// [JournalDayCubit] et l'[AcademicYearContextBloc] au sous-arbre, et les
/// ferme à la sortie.
class JournalFeatureScope extends StatefulWidget {
  final Widget child;

  const JournalFeatureScope({super.key, required this.child});

  @override
  State<JournalFeatureScope> createState() => _JournalFeatureScopeState();
}

class _JournalFeatureScopeState extends State<JournalFeatureScope> {
  late final JournalDayCubit _dayCubit;
  late final AcademicYearContextBloc _academicYearContextBloc;

  @override
  void initState() {
    super.initState();
    _dayCubit = GetIt.instance<JournalDayCubit>();
    _academicYearContextBloc = GetIt.instance<AcademicYearContextBloc>();
  }

  @override
  void dispose() {
    _dayCubit.close();
    _academicYearContextBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<JournalDayCubit>.value(value: _dayCubit),
      BlocProvider<AcademicYearContextBloc>.value(
        value: _academicYearContextBloc,
      ),
    ],
    child: widget.child,
  );
}
