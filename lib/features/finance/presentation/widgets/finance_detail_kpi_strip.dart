import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

class FinanceDetailKpiStrip extends StatelessWidget {
  final List<FinanceDetailKpiItem> items;

  const FinanceDetailKpiStrip({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AppBreakpoints.kpiStripStackMax;
        final children = items
            .map(
              (item) =>
                  _FinanceDetailKpiTile(key: ValueKey(item.label), item: item),
            )
            .toList(growable: false);

        if (compact) {
          return Column(
            children: [
              for (final child in children) ...[
                child,
                if (child != children.last)
                  const SizedBox(height: AppDimensions.spacingS),
              ],
            ],
          );
        }

        // IntrinsicHeight borne la hauteur du Row (= max des tuiles) : sans lui,
        // `crossAxisAlignment.stretch` dans un parent à hauteur non bornée
        // (SingleChildScrollView de la page) forcerait une hauteur infinie.
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                Expanded(child: children[i]),
                if (i < children.length - 1)
                  const SizedBox(width: AppDimensions.spacingM),
              ],
            ],
          ),
        );
      },
    );
  }
}

class FinanceDetailKpiItem {
  final String label;
  final String value;
  final String? suffix;
  final Color valueColor;
  final Color? suffixColor;

  /// Liseré supérieur de la tuile (spec §07). `null` → pas de liseré.
  final Color? topAccentColor;

  const FinanceDetailKpiItem({
    required this.label,
    required this.value,
    this.suffix,
    this.valueColor = AppColors.textPrimary,
    this.suffixColor,
    this.topAccentColor,
  });
}

class _FinanceDetailKpiTile extends StatelessWidget {
  final FinanceDetailKpiItem item;

  const _FinanceDetailKpiTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppTextStyles.totalAmountLora.copyWith(
      fontSize: 18,
      color: item.valueColor,
    );
    final effectiveSuffix = item.suffix?.trim();
    final accent = item.topAccentColor;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brKpi,
        border: accent != null
            ? Border(top: BorderSide(color: accent, width: 3))
            : null,
        boxShadow: const [
          BoxShadow(
            color: AppColors.financeDetailShadow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: 15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          // FittedBox plutôt qu'ellipsis : un montant tronqué (« 1 250… ») serait
          // trompeur ; on réduit la taille en dernier recours sur écran étroit.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: (effectiveSuffix == null || effectiveSuffix.isEmpty)
                ? Text(item.value, style: valueStyle)
                : Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: item.value, style: valueStyle),
                        TextSpan(
                          text: ' $effectiveSuffix',
                          style: valueStyle.copyWith(
                            color: item.suffixColor ?? item.valueColor,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
