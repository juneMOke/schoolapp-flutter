import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/utils/facturation_collect_payment_utils.dart';

/// Une ligne de la page d'encaissement : un frais payable, le montant saisi et
/// son état coché.
///
/// Vit hors de la page parce que la page tient la liste et que la section
/// « Frais à régler » la rend : c'est tout ce que les deux partagent.
class FacturationChargeEntry {
  final StudentCharge charge;
  final TextEditingController controller;
  bool selected;

  FacturationChargeEntry(this.charge)
    : controller = TextEditingController(),
      selected = false;

  int get remainingInCents => chargeRemainingInCents(charge);

  int get effectiveCents => effectiveAllocationCents(
    selected: selected,
    rawAmount: controller.text,
    remainingInCents: remainingInCents,
  );

  void dispose() => controller.dispose();
}
