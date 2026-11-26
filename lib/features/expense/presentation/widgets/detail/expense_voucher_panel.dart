import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_voucher_image.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_section_note.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/states/expense_results_error_state.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_declaration_delay.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Où en est la lecture de la photo d'un bon.
sealed class ExpenseVoucherLoad {
  const ExpenseVoucherLoad();
}

class ExpenseVoucherLoading extends ExpenseVoucherLoad {
  const ExpenseVoucherLoading();
}

class ExpenseVoucherFailed extends ExpenseVoucherLoad {
  final Failure failure;

  const ExpenseVoucherFailed(this.failure);
}

class ExpenseVoucherLoaded extends ExpenseVoucherLoad {
  /// `null` : la déclaration n'a pas de photo côté serveur.
  final ExpenseVoucherImage? image;

  const ExpenseVoucherLoaded(this.image);
}

/// La place de la chaîne de validation dans la fiche d'une **déclaration** :
/// la photo du bon en grand — c'est ce que le promoteur vient viser —, puis
/// ce que la déclaration attend.
///
/// Les trois états partagés de la règle n°10 : squelette au chargement,
/// résultat vide sans photo, erreur à quatre tonalités.
class ExpenseVoucherPanel extends StatelessWidget {
  final Expense expense;
  final ExpenseVoucherLoad load;
  final VoidCallback onRetry;

  /// La journée de caisse est figée : « Annuler » n'est plus offert, et la
  /// fiche dit pourquoi plutôt que de le taire.
  final bool cancelBlocked;

  /// L'image ne se décode pas : la fiche referme « Viser ».
  final VoidCallback? onImageError;

  const ExpenseVoucherPanel({
    super.key,
    required this.expense,
    required this.load,
    required this.onRetry,
    this.cancelBlocked = false,
    this.onImageError,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reason = expense.flagReason;
    final lateDays = ExpenseDeclarationDelay.days(expense) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _photo(l10n),
        // Le promoteur voit qu'un décaissement est arrivé tard : un envoi
        // hors ligne tardif, ou une horloge de poste faussée (E1).
        if (lateDays >= 1)
          ExpenseSectionNote(text: l10n.expenseDeclaredAfterDays(lateDays)),
        if (expense.isDeclarationToRegularize)
          ExpenseSectionNote(text: l10n.expenseToRegularizeNote),
        if (expense.visaStatus == ExpenseVisaStatus.flagged && reason != null)
          ExpenseSectionNote(text: l10n.expenseFlaggedNote(reason)),
        if (cancelBlocked && !expense.isCancelledDeclaration)
          ExpenseSectionNote(text: l10n.expenseCancelBlockedNote),
      ],
    );
  }

  Widget _photo(AppLocalizations l10n) => switch (load) {
    ExpenseVoucherLoading() => const EteeloSkeletonBox(
      height: AppDimensions.expenseVoucherDetailHeight,
    ),
    ExpenseVoucherFailed(:final failure) => ExpenseResultsErrorState(
      failure: failure,
      onRetry: onRetry,
    ),
    ExpenseVoucherLoaded(image: null) => EteeloEmptyResult(
      label: l10n.expenseVoucherMissingTitle,
      description: l10n.expenseVoucherMissing,
      medallionIcon: Icons.no_photography_outlined,
    ),
    ExpenseVoucherLoaded(:final image?) => ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.expenseInsetRadius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: AppDimensions.expenseVoucherDetailHeight,
        ),
        child: image.isPdf
            ? _PdfMark(label: l10n.expenseVoucherPdf)
            : InteractiveViewer(
                child: Image.memory(
                  image.bytes,
                  fit: BoxFit.contain,
                  semanticLabel: l10n.expenseVoucherLabel,
                  errorBuilder: (_, _, _) {
                    onImageError?.call();
                    return _PdfMark(
                      label: l10n.expenseVoucherLabel,
                      icon: Icons.broken_image_outlined,
                    );
                  },
                ),
              ),
      ),
    ),
  };
}

class _PdfMark extends StatelessWidget {
  final String label;
  final IconData icon;

  const _PdfMark({
    required this.label,
    this.icon = Icons.picture_as_pdf_outlined,
  });

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surfaceAlt,
    child: Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary),
            const SizedBox(height: AppDimensions.spacingS),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}
