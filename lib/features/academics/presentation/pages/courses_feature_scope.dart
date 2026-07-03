import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/course_bloc.dart';

/// Scope du module Cours : fournit le [CourseBloc] au sous-arbre et le ferme
/// à la sortie de la feature (cf. AGENTS.md §11 — FeatureScope).
class CoursesFeatureScope extends StatefulWidget {
  final Widget child;

  const CoursesFeatureScope({super.key, required this.child});

  @override
  State<CoursesFeatureScope> createState() => _CoursesFeatureScopeState();
}

class _CoursesFeatureScopeState extends State<CoursesFeatureScope> {
  late final CourseBloc _courseBloc;

  @override
  void initState() {
    super.initState();
    _courseBloc = GetIt.instance<CourseBloc>();
  }

  @override
  void dispose() {
    _courseBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CourseBloc>.value(
      value: _courseBloc,
      child: widget.child,
    );
  }
}
