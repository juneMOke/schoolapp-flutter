import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_journey_pill_button.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_candidate.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_target.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/enrollment_suspension_status_cubit.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/suspension_flow.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspended_banner.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspension_start_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La désactivation dans la consultation d'un dossier : l'état suivi, le
/// bouton de la barre sombre et le bandeau en tête du contenu.
class ConsultationSuspensionScope extends StatelessWidget {
  final String enrollmentId;
  final Widget child;

  const ConsultationSuspensionScope({
    super.key,
    required this.enrollmentId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<EnrollmentSuspensionStatusCubit>(param1: enrollmentId),
    child: child,
  );
}

/// La cible d'un geste depuis le dossier consulté.
SuspensionCandidate consultationCandidate(LocalEnrollmentDetail detail) =>
    SuspensionCandidate(
      target: SuspensionTarget(
        enrollmentId: detail.enrollment.id,
        studentId: detail.student.id,
        academicYearId: detail.enrollment.academicYearId,
      ),
      lastName: detail.student.lastName,
      middleName: detail.student.surname,
      firstName: detail.student.firstName,
    );

/// « Désactiver » ou « Réactiver », en pilule sur la barre sombre.
class ConsultationSuspensionAction extends StatelessWidget {
  final SuspensionCandidate candidate;

  const ConsultationSuspensionAction({super.key, required this.candidate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = context.watch<EnrollmentSuspensionStatusCubit>().state;
    final suspended = status.isSuspended;
    return SuspensionGate(
      child: EnrollmentJourneyPillButton(
        label: suspended ? l10n.reactivationConfirm : l10n.suspensionConfirm(1),
        icon: suspended
            ? Icons.how_to_reg_outlined
            : Icons.person_remove_outlined,
        positive: suspended,
        onPressed: () => suspended
            ? SuspensionFlow.reactivate(context, [
                candidate,
              ], suspension: status.period)
            : SuspensionFlow.suspend(context, [candidate]),
      ),
    );
  }
}

/// Le bandeau d'un élève désactivé, au-dessus du bandeau « Lecture seule » ;
/// rien sinon.
class ConsultationSuspendedBanner extends StatelessWidget {
  final SuspensionCandidate candidate;

  const ConsultationSuspendedBanner({super.key, required this.candidate});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<EnrollmentSuspensionStatusCubit>().state;
    final period = status.period;
    if (!status.isSuspended || period == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SuspendedBanner(
        suspension: period,
        onReactivate: () =>
            SuspensionFlow.reactivate(context, [candidate], suspension: period),
      ),
    );
  }
}
