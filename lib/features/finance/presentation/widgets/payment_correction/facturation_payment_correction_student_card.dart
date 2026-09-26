import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_target.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'élève du remplaçant (D1) : celui de l'origine, ou un autre élève inscrit
/// la même année — le frère au lieu de la sœur.
///
/// « Changer » déplie une recherche en place, sans modale imbriquée. Un élève
/// retenu passe la carte en ambre et dit d'où le versement part.
class FacturationPaymentCorrectionStudentCard extends StatefulWidget {
  /// Nom de l'élève d'origine.
  final String originName;

  /// L'élève retenu, `null` tant que le versement reste sur l'origine.
  final PaymentCorrectionTarget? target;

  final List<PaymentCorrectionTarget> results;
  final String query;
  final ValueChanged<String> onSearch;
  final ValueChanged<PaymentCorrectionTarget> onSelect;
  final VoidCallback onRestore;

  /// Ses frais sont tous soldés : il n'y a rien à lui imputer.
  final bool targetSettled;

  final bool loadFailed;
  final bool enabled;

  const FacturationPaymentCorrectionStudentCard({
    super.key,
    required this.originName,
    required this.target,
    required this.results,
    required this.query,
    required this.onSearch,
    required this.onSelect,
    required this.onRestore,
    this.targetSettled = false,
    this.loadFailed = false,
    this.enabled = true,
  });

  @override
  State<FacturationPaymentCorrectionStudentCard> createState() =>
      _FacturationPaymentCorrectionStudentCardState();
}

class _FacturationPaymentCorrectionStudentCardState
    extends State<FacturationPaymentCorrectionStudentCard> {
  final _search = TextEditingController();
  bool _open = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(
    covariant FacturationPaymentCorrectionStudentCard oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    // Un élève vient d'être retenu : le panneau de recherche se replie.
    if (widget.target != null && oldWidget.target != widget.target) {
      _open = false;
      _search.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final target = widget.target;
    final moved = target != null;
    final name = target?.fullName ?? widget.originName;

    return FinanceSectionCard(
      backgroundColor: moved
          ? AppColors.warning.withValues(alpha: 0.08)
          : AppColors.surfaceRaised,
      borderColor: moved ? AppColors.warning : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.paymentCorrectionStudentLabel,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  key: const ValueKey('payment-correction-student-name'),
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton.icon(
                key: ValueKey(
                  moved
                      ? 'payment-correction-restore-student'
                      : 'payment-correction-change-student',
                ),
                onPressed: !widget.enabled
                    ? null
                    : moved
                    ? widget.onRestore
                    : () => setState(() => _open = !_open),
                icon: Icon(
                  moved ? Icons.undo_rounded : Icons.search_rounded,
                  size: 18,
                ),
                label: Text(
                  moved
                      ? l10n.paymentCorrectionRestoreStudent
                      : l10n.paymentCorrectionChangeStudent,
                ),
              ),
            ],
          ),
          if (moved)
            Text(
              l10n.paymentCorrectionMovedFrom(widget.originName),
              style: AppTextStyles.caption.copyWith(color: AppColors.warning),
            ),
          if (moved && widget.targetSettled)
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.spacingXS),
              child: Text(
                l10n.paymentCorrectionTargetSettled(name),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          if (widget.loadFailed)
            Text(
              l10n.paymentCorrectionTargetLoadFailed,
              style: AppTextStyles.caption.copyWith(color: AppColors.danger),
            ),
          if (_open && !moved) ...[
            const SizedBox(height: AppDimensions.spacingS),
            EteeloTextInput(
              key: const ValueKey('payment-correction-student-search'),
              controller: _search,
              label: l10n.paymentCorrectionStudentSearchLabel,
              onChanged: widget.onSearch,
            ),
            for (final result in widget.results)
              ListTile(
                key: ValueKey('payment-correction-target-${result.studentId}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(result.fullName),
                subtitle: result.levelName == null
                    ? null
                    : Text(result.levelName!),
                onTap: () => widget.onSelect(result),
              ),
            if (widget.query.trim().isNotEmpty && widget.results.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppDimensions.spacingS),
                child: Text(
                  l10n.paymentCorrectionStudentNoResult,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
