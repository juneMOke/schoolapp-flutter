import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/currency_tones.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_register_rules.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le choix de la devise d'une nouvelle caisse : deux tuiles, celle qui est
/// choisie prend le pavé de sa devise. Une devise qui a déjà sa caisse est
/// désactivée, et dit pourquoi (v1 : une caisse par devise).
class CurrencyChoice extends StatelessWidget {
  final TreasuryCurrency selected;
  final List<CashRegister> existing;
  final ValueChanged<TreasuryCurrency>? onChanged;

  const CurrencyChoice({
    super.key,
    required this.selected,
    required this.existing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.treasuryFormCurrency, style: AppTypography.labelFormMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final currency in TreasuryCurrency.values)
              _CurrencyTile(
                currency: currency,
                selected: currency == selected,
                available: CashRegisterRules.canCreateRegister(
                  currency,
                  existing,
                ),
                onTap: onChanged == null ? null : () => onChanged!(currency),
              ),
          ],
        ),
      ],
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  final TreasuryCurrency currency;
  final bool selected;
  final bool available;
  final VoidCallback? onTap;

  const _CurrencyTile({
    required this.currency,
    required this.selected,
    required this.available,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = TreasuryFormat.currencyName(l10n, currency);
    final ink = selected ? DashboardTones.inkValeur : AppColors.textPrimary;
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppDimensions.treasuryRegisterCardMinWidth / 2,
        minHeight: AppDimensions.minTouchTarget,
      ),
      child: Semantics(
        selected: selected,
        enabled: available,
        inMutuallyExclusiveGroup: true,
        child: Material(
          color: selected
              ? CurrencyTones.pave(currency.code)
              : AppColors.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brMd,
            side: BorderSide(
              color: selected ? Colors.transparent : AppColors.border,
            ),
          ),
          child: InkWell(
            borderRadius: AppRadius.brMd,
            onTap: available ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${TreasuryFormat.symbol(currency)} · $name',
                    style: AppTypography.titleSmall.copyWith(
                      color: available ? ink : AppColors.textMuted,
                    ),
                  ),
                  Text(
                    available
                        ? currency.code
                        : l10n.treasuryCurrencyTaken(name.toLowerCase()),
                    style: AppTypography.labelSmall.copyWith(
                      color: selected
                          ? DashboardTones.inkSousLigne
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
