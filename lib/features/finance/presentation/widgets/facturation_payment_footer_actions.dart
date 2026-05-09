import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

class FacturationPaymentFooterActions extends StatelessWidget {
  final String downloadLabel;
  final String printLabel;
  final VoidCallback onDownloadPdf;
  final VoidCallback onPrintReceipt;

  const FacturationPaymentFooterActions({
    super.key,
    required this.downloadLabel,
    required this.printLabel,
    required this.onDownloadPdf,
    required this.onPrintReceipt,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            border: Border(
              top: BorderSide(color: AppColors.borderStrong.withValues(alpha: 0.2)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: downloadLabel,
                      icon: compact ? null : Icons.picture_as_pdf_outlined,
                      onPressed: onDownloadPdf,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: PrimaryButton(
                      label: printLabel,
                      icon: compact ? null : Icons.print_outlined,
                      onPressed: onPrintReceipt,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
