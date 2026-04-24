import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_row.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';

class StudentChargesList extends StatelessWidget {
  final List<StudentCharge> studentCharges;
  final Map<String, TextEditingController> amountControllers;
  final Map<String, String?> amountErrors;
  final bool isEditable;
  final ValueChanged<String> onAmountChanged;

  const StudentChargesList({
    super.key,
    required this.studentCharges,
    required this.amountControllers,
    required this.amountErrors,
    required this.isEditable,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: studentCharges.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.spacingM),
      itemBuilder: (context, index) {
        final charge = studentCharges[index];
        final controller = amountControllers[charge.id];
        if (controller == null) {
          return const SizedBox.shrink();
        }

        return StudentChargeRow(
          key: ValueKey(charge.id),
          studentCharge: charge,
          amountController: controller,
          amountErrorText: amountErrors[charge.id],
          isEditable: isEditable,
          onAmountChanged: onAmountChanged,
        );
      },
    );
  }
}
