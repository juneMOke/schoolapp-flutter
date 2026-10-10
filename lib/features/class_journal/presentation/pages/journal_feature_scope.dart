import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';

/// Scope du journal de classe (cf. AGENTS.md §11 — FeatureScope) : fournit
/// l'[AcademicYearContextBloc] au sous-arbre et le ferme à la sortie. Les
/// cubits du journal naissent sous le coordinateur, selon le rôle, et se
/// ferment avec lui.
class JournalFeatureScope extends StatefulWidget {
  final Widget child;

  const JournalFeatureScope({super.key, required this.child});

  @override
  State<JournalFeatureScope> createState() => _JournalFeatureScopeState();
}

class _JournalFeatureScopeState extends State<JournalFeatureScope> {
  late final AcademicYearContextBloc _academicYearContextBloc;

  @override
  void initState() {
    super.initState();
    _academicYearContextBloc = GetIt.instance<AcademicYearContextBloc>();
  }

  @override
  void dispose() {
    _academicYearContextBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocProvider<AcademicYearContextBloc>.value(
        value: _academicYearContextBloc,
        child: widget.child,
      );
}
