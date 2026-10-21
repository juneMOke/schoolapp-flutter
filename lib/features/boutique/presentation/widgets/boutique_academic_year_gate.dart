import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';

/// Le gate du contexte académique, commun aux écrans de la boutique : la
/// boutique se lit et s'encaisse **par exercice**, et sans année courante il
/// n'y a pas de périmètre.
///
/// Il redemande le contexte au montage, attend, et ne rend [builder] qu'une
/// fois l'année résolue.
class BoutiqueAcademicYearGate extends StatefulWidget {
  final Widget Function(BuildContext context, AcademicYearContext? year)
  builder;

  const BoutiqueAcademicYearGate({super.key, required this.builder});

  @override
  State<BoutiqueAcademicYearGate> createState() =>
      _BoutiqueAcademicYearGateState();
}

class _BoutiqueAcademicYearGateState extends State<BoutiqueAcademicYearGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AcademicYearContextBloc>().add(
        const AcademicYearContextRequested(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status || prev.context != curr.context,
      builder: (context, state) {
        if (state.status == AcademicYearContextLoadStatus.loading ||
            state.status == AcademicYearContextLoadStatus.initial) {
          return const AppPageBackground(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingXL),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (state.status != AcademicYearContextLoadStatus.success) {
          return AppPageBackground(
            child: BootstrapContextError(
              onLogout: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            ),
          );
        }
        return widget.builder(context, state.context);
      },
    );
  }
}
