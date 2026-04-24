import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_empty_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_error_l10n_extension.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_error_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_list.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_loading_state.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class StudentChargesStepBody extends StatelessWidget {
  final AppLocalizations l10n;
  final StudentChargesStatus status;
  final StudentChargesErrorType errorType;
  final List<StudentCharge> studentCharges;
  final Map<String, TextEditingController> amountControllers;
  final Map<String, String?> amountErrors;
  final bool isEditable;
  final VoidCallback onRetry;
  final ValueChanged<String> onAmountChanged;
  final String? unavailableMessage;

  const StudentChargesStepBody({
    super.key,
    required this.l10n,
    required this.status,
    required this.errorType,
    required this.studentCharges,
    required this.amountControllers,
    required this.amountErrors,
    required this.isEditable,
    required this.onRetry,
    required this.onAmountChanged,
    this.unavailableMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (unavailableMessage != null) {
      return StudentChargesErrorState(message: unavailableMessage!);
    }

    return switch (status) {
      StudentChargesStatus.initial ||
      StudentChargesStatus.loading => const StudentChargesLoadingState(),
      StudentChargesStatus.failure => StudentChargesErrorState(
        message: errorType.localizedMessage(l10n),
        onRetry: onRetry,
      ),
      StudentChargesStatus.success =>
        studentCharges.isEmpty
            ? const StudentChargesEmptyState()
            : Padding(
                padding: const EdgeInsets.only(top: AppDimensions.spacingS),
                child: StudentChargesList(
                  studentCharges: studentCharges,
                  amountControllers: amountControllers,
                  amountErrors: amountErrors,
                  isEditable: isEditable,
                  onAmountChanged: onAmountChanged,
                ),
              ),
    };
  }
}
