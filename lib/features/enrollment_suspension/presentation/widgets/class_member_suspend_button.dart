import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_candidate.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/usecases/enrollment_suspension_use_cases.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/suspension_flow.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspension_start_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'icône « Désactiver » d'une ligne élève de la composition des classes,
/// avant « Transférer ». Le membre ne porte pas son inscription : elle se
/// retrouve au geste.
class ClassMemberSuspendButton extends StatelessWidget {
  final String studentId;
  final String academicYearId;
  final String lastName;
  final String? middleName;
  final String firstName;
  final String classLabel;

  const ClassMemberSuspendButton({
    super.key,
    required this.studentId,
    required this.academicYearId,
    required this.lastName,
    required this.firstName,
    required this.classLabel,
    this.middleName,
  });

  static const double _size = 32;

  Future<void> _onPressed(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await getIt<ResolveSuspensionTargetUseCase>()(
      studentId: studentId,
      academicYearId: academicYearId,
    );
    if (!context.mounted) return;
    final target = result.fold((_) => null, (t) => t);
    if (target == null) {
      AppSnackBar.showWarning(context, l10n.suspensionNoEnrollment);
      return;
    }
    await SuspensionFlow.suspend(context, [
      SuspensionCandidate(
        target: target,
        lastName: lastName,
        middleName: middleName,
        firstName: firstName,
        classLabel: classLabel,
      ),
    ], doneMessage: (l10n, count) => l10n.suspensionDoneClasses(count));
  }

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(
      context,
    )!.suspensionMemberAction('$lastName $firstName');
    return SuspensionGate(
      child: Tooltip(
        message: label,
        child: IconButton(
          onPressed: () => _onPressed(context),
          icon: const Icon(Icons.person_remove_outlined, size: 15),
          color: AppColors.textSecondary,
          // Cible tactile ≥ 44 dp autour d'un rond de 32.
          constraints: const BoxConstraints(
            minWidth: AppDimensions.minTouchTarget,
            minHeight: AppDimensions.minTouchTarget,
          ),
          style: IconButton.styleFrom(
            fixedSize: const Size.square(_size),
            shape: const CircleBorder(
              side: BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ),
    );
  }
}
