import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_identity.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/student_identity_cubit.dart';

/// Fiche ouverte par son adresse, sans le contexte que la navigation lui
/// passe d'ordinaire (onglet rechargé, lien collé, Ctrl+clic) : l'identité de
/// l'élève est relue en base locale avant de construire la page.
///
/// [builder] reçoit `null` quand l'élève est introuvable ; la page garde
/// alors sa propre carte « contexte indisponible ».
class StudentIdentityGate extends StatelessWidget {
  final String studentId;
  final String academicYearId;
  final Widget Function(StudentIdentity? identity) builder;

  const StudentIdentityGate({
    super.key,
    required this.studentId,
    required this.academicYearId,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StudentIdentityCubit>(
      create: (_) =>
          getIt<StudentIdentityCubit>()
            ..resolve(studentId: studentId, academicYearId: academicYearId),
      child: BlocBuilder<StudentIdentityCubit, StudentIdentityState>(
        buildWhen: (prev, curr) => prev.resolved != curr.resolved,
        builder: (context, state) => state.resolved
            ? builder(state.identity)
            : const AppPageBackground(
                scrollable: false,
                child: EteeloListSkeleton(rowCount: 4),
              ),
      ),
    );
  }
}
