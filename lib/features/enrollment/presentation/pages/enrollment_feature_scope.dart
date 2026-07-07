import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_previous_year_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';

class EnrollmentFeatureScope extends StatefulWidget {
  final Widget child;

  const EnrollmentFeatureScope({super.key, required this.child});

  @override
  State<EnrollmentFeatureScope> createState() => _EnrollmentFeatureScopeState();
}

class _EnrollmentFeatureScopeState extends State<EnrollmentFeatureScope> {
  late final EnrollmentBloc _enrollmentBloc;
  late final EnrollmentOfflineBloc _enrollmentOfflineBloc;
  // Wizard offline-first du parcours NEW : brouillon local persisté par étape.
  late final EnrollmentDraftBloc _enrollmentDraftBloc;
  late final BootstrapCurrentYearBloc _bootstrapCurrentYearBloc;
  late final BootstrapPreviousYearBloc _bootstrapPreviousYearBloc;

  @override
  void initState() {
    super.initState();
    _enrollmentBloc = GetIt.instance<EnrollmentBloc>();
    _enrollmentOfflineBloc = GetIt.instance<EnrollmentOfflineBloc>();
    _enrollmentDraftBloc = GetIt.instance<EnrollmentDraftBloc>();
    _bootstrapCurrentYearBloc = GetIt.instance<BootstrapCurrentYearBloc>();
    _bootstrapPreviousYearBloc = GetIt.instance<BootstrapPreviousYearBloc>();
  }

  @override
  void dispose() {
    _enrollmentBloc.close();
    _enrollmentOfflineBloc.close();
    _enrollmentDraftBloc.close();
    _bootstrapCurrentYearBloc.close();
    _bootstrapPreviousYearBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EnrollmentBloc>.value(value: _enrollmentBloc),
        BlocProvider<EnrollmentOfflineBloc>.value(
          value: _enrollmentOfflineBloc,
        ),
        BlocProvider<EnrollmentDraftBloc>.value(value: _enrollmentDraftBloc),
        BlocProvider<BootstrapCurrentYearBloc>.value(
          value: _bootstrapCurrentYearBloc,
        ),
        BlocProvider<BootstrapPreviousYearBloc>.value(
          value: _bootstrapPreviousYearBloc,
        ),
      ],
      child: widget.child,
    );
  }
}
