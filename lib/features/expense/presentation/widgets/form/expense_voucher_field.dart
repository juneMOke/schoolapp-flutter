import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/form/expense_form_fields.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La photo du bon d'une déclaration — **obligatoire** (contrat, 25/11).
///
/// Vide : un seul geste, « Ajouter la photo du bon », qui ouvre la feuille
/// commune de capture (appareil photo, photothèque, PDF). Prise : la vignette
/// (ou la marque d'un PDF), son poids, et « Remplacer ».
class ExpenseVoucherField extends StatelessWidget {
  final CapturedDocument? voucher;

  /// La soumission a été tentée : une photo manquante se dit alors en rouge.
  final bool touched;
  final VoidCallback onCapture;

  const ExpenseVoucherField({
    super.key,
    required this.voucher,
    required this.touched,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final voucher = this.voucher;
    return ExpenseLabelled(
      label: l10n.expenseVoucherLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (voucher != null) ...[
            _Preview(voucher: voucher),
            const SizedBox(height: AppDimensions.spacingS),
          ],
          EteeloButton.secondary(
            label: voucher == null
                ? l10n.expenseVoucherAdd
                : l10n.expenseVoucherReplace,
            icon: voucher == null
                ? Icons.add_a_photo_outlined
                : Icons.flip_camera_android_outlined,
            onPressed: onCapture,
            fullWidth: false,
          ),
          if (touched && voucher == null) ...[
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              l10n.expenseVoucherRequired,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  final CapturedDocument voucher;

  const _Preview({required this.voucher});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final kilobytes = (voucher.bytes.length / 1024).ceil();
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(
            AppDimensions.expenseIconBoxRadius,
          ),
          child: SizedBox(
            height: AppDimensions.expenseVoucherThumbHeight,
            width: AppDimensions.expenseVoucherThumbHeight,
            child: voucher.mimeType.isImage
                ? Image.memory(
                    voucher.bytes,
                    fit: BoxFit.cover,
                    semanticLabel: l10n.expenseVoucherLabel,
                    // Une image qui ne se décode pas reste une pièce prise :
                    // le serveur la jugera, la vignette ne doit pas tomber.
                    errorBuilder: (_, _, _) =>
                        const _Placeholder(icon: Icons.image_outlined),
                  )
                : const _Placeholder(icon: Icons.picture_as_pdf_outlined),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Text(
            l10n.expenseVoucherSize(kilobytes),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  final IconData icon;

  const _Placeholder({required this.icon});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surfaceAlt,
    child: Center(child: Icon(icon, color: AppColors.textSecondary)),
  );
}
