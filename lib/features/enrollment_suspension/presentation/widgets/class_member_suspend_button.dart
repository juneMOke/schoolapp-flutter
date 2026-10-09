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
class ClassMemberSuspendButton extends StatefulWidget {
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

  @override
  State<ClassMemberSuspendButton> createState() =>
      _ClassMemberSuspendButtonState();
}

class _ClassMemberSuspendButtonState extends State<ClassMemberSuspendButton> {
  /// Un second appui pendant la résolution n'ouvre pas une seconde modale.
  bool _busy = false;

  Future<void> _onPressed() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _suspend();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _suspend() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await getIt<ResolveSuspensionTargetUseCase>()(
      studentId: widget.studentId,
      academicYearId: widget.academicYearId,
    );
    if (!mounted) return;
    final target = result.fold((_) => null, (t) => t);
    if (target == null) {
      AppSnackBar.showWarning(context, l10n.suspensionNoEnrollment);
      return;
    }
    await SuspensionFlow.suspend(context, [
      SuspensionCandidate(
        target: target,
        lastName: widget.lastName,
        middleName: widget.middleName,
        firstName: widget.firstName,
        classLabel: widget.classLabel,
      ),
    ], doneMessage: (l10n, count) => l10n.suspensionDoneClasses(count));
  }

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(
      context,
    )!.suspensionMemberAction('${widget.lastName} ${widget.firstName}');
    return SuspensionGate(
      child: Tooltip(
        message: label,
        child: IconButton(
          onPressed: _busy ? null : _onPressed,
          icon: const Icon(
            Icons.person_remove_outlined,
            size: AppDimensions.insPaveMedallionIconSize,
          ),
          color: AppColors.textSecondary,
          // Un rond de 32 ; la cible tactile Material l'entoure.
          style: IconButton.styleFrom(
            fixedSize: const Size.square(
              AppDimensions.suspensionMemberButtonSize,
            ),
            minimumSize: const Size.square(
              AppDimensions.suspensionMemberButtonSize,
            ),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.padded,
            shape: const CircleBorder(
              side: BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ),
    );
  }
}
