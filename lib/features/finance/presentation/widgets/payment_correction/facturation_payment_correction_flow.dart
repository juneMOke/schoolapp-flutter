import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/load_payment_correction_origin_use_case.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_payment_correction_context.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/payment_correction/facturation_payment_cancel_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Le geste « Annuler », ouvert depuis la fiche. Rend `true` quand
/// l'annulation a été écrite : la fiche relit alors ses listes.
Future<bool> runFacturationPaymentCancel(
  BuildContext context, {
  required Payment payment,
}) => showFacturationPaymentCancelDialog(
  context,
  paymentId: payment.id,
  amountLabel: payment.amounts.entries.map(MoneyFormat.format).join(' · '),
  dateLabel: MaterialLocalizations.of(context).formatShortDate(payment.paidAt),
);

/// Le geste « Corriger » : la page d'encaissement, pré-remplie avec
/// l'origine et ses tranches rouvertes. Rend `true` quand la correction a été
/// écrite.
Future<bool> runFacturationPaymentCorrection(
  BuildContext context, {
  required FacturationDetailIntent detail,
  required Payment payment,
  required List<StudentCharge> charges,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  final loaded = await getIt<LoadPaymentCorrectionOriginUseCase>()(payment.id);
  if (!context.mounted) return false;

  final origin = loaded.fold((_) => null, (origin) => origin);
  if (origin == null) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.paymentCorrectionLoadFailed)),
    );
    return false;
  }

  final corrected = await context.push<bool>(
    AppRoutesNames.facturationCreatePaymentPath(
      studentId: detail.studentId,
      academicYearId: detail.academicYearId,
    ),
    extra: FacturationCreatePaymentIntent(
      studentId: detail.studentId,
      academicYearId: detail.academicYearId,
      firstName: detail.firstName,
      lastName: detail.lastName,
      surname: detail.surname,
      levelName: detail.levelName,
      levelGroupName: detail.levelGroupName,
      studentCharges: chargesWithoutPayment(charges, origin.centsByCharge),
      correction: FacturationPaymentCorrectionContext(
        origin: origin,
        originAmounts: payment.amounts,
        originPaidAt: payment.paidAt,
      ),
    ),
  );
  return corrected == true;
}
