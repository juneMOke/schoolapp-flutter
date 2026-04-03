import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';

class EnrollmentFeatureScope extends StatefulWidget {
  final Widget child;

  const EnrollmentFeatureScope({super.key, required this.child});

  @override
  State<EnrollmentFeatureScope> createState() => _EnrollmentFeatureScopeState();
}

class _EnrollmentFeatureScopeState extends State<EnrollmentFeatureScope> {
  late final EnrollmentBloc _enrollmentBloc;

  @override
  void initState() {
    super.initState();
    _enrollmentBloc = GetIt.instance<EnrollmentBloc>();
  }

  @override
  void dispose() {
    _enrollmentBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider<EnrollmentBloc>.value(value: _enrollmentBloc)],
      child: widget.child,
    );
  }
}
