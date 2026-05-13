import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';

class FacturationCreatePaymentAllocationDraft {
  StudentCharge? selectedCharge;
  final TextEditingController amountController;

  FacturationCreatePaymentAllocationDraft()
    : amountController = TextEditingController();

  void dispose() => amountController.dispose();
}
