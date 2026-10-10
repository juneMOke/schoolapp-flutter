import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/open_suspensions_count_cubit.dart';

/// Le nombre d'élèves désactivés de l'année courante, compté sur la tablette
/// et tenu à jour ; 0 tant que l'année n'est pas connue.
class SuspendedCountBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, int count) builder;

  const SuspendedCountBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final yearId = context.select(
      (AcademicYearContextBloc b) => b.state.context?.academicYear.id,
    );
    if (yearId == null || yearId.isEmpty) return builder(context, 0);
    return BlocProvider(
      key: ValueKey(yearId),
      create: (_) => getIt<OpenSuspensionsCountCubit>(param1: yearId),
      child: BlocBuilder<OpenSuspensionsCountCubit, int>(
        builder: (context, count) => builder(context, count),
      ),
    );
  }
}
