import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_result_medallion.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/ticket_print_status_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_ticket_print_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le résultat d'une correction : un succès LOCAL, et le ticket du remplaçant
/// à imprimer tout de suite — le parent repart avec le bon papier.
Future<void> showFacturationPaymentCorrectedDialog(
  BuildContext context, {
  required String? replacementPaymentId,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => FacturationPaymentCorrectedDialog(
    replacementPaymentId: replacementPaymentId,
  ),
);

class FacturationPaymentCorrectedDialog extends StatelessWidget {
  final String? replacementPaymentId;

  const FacturationPaymentCorrectedDialog({
    super.key,
    required this.replacementPaymentId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final replacement = replacementPaymentId;
    return Dialog(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.facturationModalMaxWidth,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EteeloResultMedallion(kind: EteeloResultKind.success),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                l10n.paymentCorrectionCorrectedDone,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                l10n.paymentCorrectionSavedOnTablet,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (replacement != null) ...[
                const SizedBox(height: AppDimensions.spacingM),
                BlocProvider<TicketPrintStatusCubit>(
                  create: (_) =>
                      getIt<TicketPrintStatusCubit>()..load(replacement),
                  child: FacturationTicketPrintRow(paymentId: replacement),
                ),
              ],
              const SizedBox(height: AppDimensions.spacingL),
              FilledButton(
                key: const ValueKey('payment-correction-corrected-close'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.facturationPaymentCloseLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
