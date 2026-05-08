import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
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

  double _draftAmountFor(StudentCharge charge) {
    final parsed = parseMonetaryAmount(amountControllers[charge.id]?.text ?? '');
    return parsed ?? charge.expectedAmountInCents;
  }

  double _computeTotalAmount() {
    return studentCharges.fold<double>(
      0,
      (sum, charge) => sum + _draftAmountFor(charge),
    );
  }

  String _displayCurrency() {
    if (studentCharges.isEmpty) {
      return '';
    }

    return studentCharges.first.currency;
  }

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StudentChargesList(
                      l10n: l10n,
                      studentCharges: studentCharges,
                      amountControllers: amountControllers,
                      amountErrors: amountErrors,
                      isEditable: isEditable,
                      onAmountChanged: onAmountChanged,
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.studentChargesTotalLabel,
                            style: AppTextStyles.bodyStrong.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Text(
                          formatMonetaryAmountWithCurrency(
                            amount: _computeTotalAmount(),
                            currency: _displayCurrency(),
                          ),
                          style: AppTextStyles.totalAmountLora.copyWith(
                            color: AppColors.bleuArdoise,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    };
  }
}
