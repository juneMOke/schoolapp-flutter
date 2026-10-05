import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/edit/student_photo_draft_cubit.dart';

/// La photo d'une nouvelle inscription : gardée en brouillon, publiée quand
/// l'étape 1 écrit la fiche de l'élève sur le poste.
///
/// Posée autour du parcours d'une nouvelle inscription seulement ; ailleurs,
/// l'élève existe et sa photo s'enregistre aussitôt.
class EnrollmentPhotoDraftScope extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const EnrollmentPhotoDraftScope({
    super.key,
    required this.enabled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return BlocProvider(
      create: (_) => getIt<StudentPhotoDraftCubit>(),
      child: BlocListener<EnrollmentOfflineBloc, EnrollmentOfflineState>(
        listenWhen: (previous, current) =>
            previous != current && current is EnrollmentDraftDetailLoaded,
        listener: (context, state) {
          if (state is EnrollmentDraftDetailLoaded) {
            context.read<StudentPhotoDraftCubit>().studentSaved(
              state.detail.student.id,
            );
          }
        },
        child: child,
      ),
    );
  }
}
