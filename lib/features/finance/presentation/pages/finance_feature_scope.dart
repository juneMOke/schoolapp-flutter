import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';

/// Scope BLoC dédié au module Finance.
///
/// Instancie ses propres instances de [EnrollmentBloc] et
/// [BootstrapCurrentYearBloc] via la factory GetIt — complètement isolées
/// des instances gérées par [EnrollmentFeatureScope].
class FinanceFeatureScope extends StatefulWidget {
  final Widget child;

  const FinanceFeatureScope({super.key, required this.child});

  @override
  State<FinanceFeatureScope> createState() => _FinanceFeatureScopeState();
}

class _FinanceFeatureScopeState extends State<FinanceFeatureScope> {
  late final EnrollmentBloc _enrollmentBloc;
  late final BootstrapCurrentYearBloc _bootstrapCurrentYearBloc;

  @override
  void initState() {
    super.initState();
    _enrollmentBloc = GetIt.instance<EnrollmentBloc>();
    _bootstrapCurrentYearBloc = GetIt.instance<BootstrapCurrentYearBloc>();
  }

  @override
  void dispose() {
    _enrollmentBloc.close();
    _bootstrapCurrentYearBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EnrollmentBloc>.value(value: _enrollmentBloc),
        BlocProvider<BootstrapCurrentYearBloc>.value(
          value: _bootstrapCurrentYearBloc,
        ),
      ],
      child: widget.child,
    );
  }
}
