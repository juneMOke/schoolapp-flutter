import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/cash_registers_repository.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/register_adjustments_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/registers/register_adjustments_list.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/registers/register_card_header.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_tones.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une caisse de l'écran Configuration : ce qu'elle détient, sa mise en
/// service, son montant d'ouverture, ses ajustements — et, pour le promoteur,
/// le geste « Ajuster le montant détenu ».
class RegisterCard extends StatefulWidget {
  final RegisterConfig config;
  final bool isNew;

  /// `null` hors promoteur : le bouton disparaît (§04).
  final VoidCallback? onAdjust;

  /// « Voir la journée de cette caisse » : la clôture, journée du jour.
  final VoidCallback? onSeeDay;

  const RegisterCard({
    super.key,
    required this.config,
    required this.isNew,
    this.onAdjust,
    this.onSeeDay,
  });

  @override
  State<RegisterCard> createState() => _RegisterCardState();
}

class _RegisterCardState extends State<RegisterCard> {
  var _historyOpen = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = widget.config;
    final register = config.register;
    final adjust = widget.onAdjust;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
        boxShadow: TreasuryTones.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RegisterCardHeader(config: config, isNew: widget.isNew),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _KeyValue(
                    label: l10n.treasuryInService,
                    value: l10n.treasuryDateShort(register.inServiceOn),
                  ),
                  _KeyValue(
                    label: l10n.treasuryOpeningAmount,
                    value: TreasuryFormat.money(
                      register.openingAmountInCents,
                      register.currency,
                    ),
                    tabular: true,
                  ),
                  _adjustmentsRow(l10n),
                  if (_historyOpen)
                    BlocProvider(
                      create: (_) => RegisterAdjustmentsCubit(
                        GetIt.instance<CashRegistersRepository>(),
                        registerId: register.id,
                      )..load(),
                      child: RegisterAdjustmentsList(
                        currency: register.currency,
                      ),
                    ),
                  if (adjust != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    if (config.closedToday)
                      _ClosedTodayNote(text: l10n.treasuryClosedShort)
                    else
                      EteeloButton.secondary(
                        label: l10n.treasuryAdjustButton,
                        icon: Icons.edit_outlined,
                        onPressed: adjust,
                      ),
                  ],
                  if (widget.onSeeDay case final seeDay?) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(
                            0,
                            AppDimensions.minTouchTarget,
                          ),
                        ),
                        onPressed: seeDay,
                        icon: const Icon(Icons.arrow_forward),
                        iconAlignment: IconAlignment.end,
                        label: Text(l10n.treasurySeeDay),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adjustmentsRow(AppLocalizations l10n) {
    final count = widget.config.adjustmentsCount;
    if (count == 0) {
      return _KeyValue(label: l10n.treasuryAdjustments, value: '0');
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.treasuryAdjustments,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton.icon(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, AppDimensions.minTouchTarget),
          ),
          onPressed: () => setState(() => _historyOpen = !_historyOpen),
          icon: Icon(_historyOpen ? Icons.expand_less : Icons.expand_more),
          iconAlignment: IconAlignment.end,
          label: Text(
            _historyOpen
                ? l10n.treasuryAdjustmentsHide
                : l10n.treasuryAdjustmentsSee(count),
          ),
        ),
      ],
    );
  }
}

class _KeyValue extends StatelessWidget {
  final String label;
  final String value;
  final bool tabular;

  const _KeyValue({
    required this.label,
    required this.value,
    this.tabular = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        // Le libellé cède la place, jamais le montant.
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
          softWrap: false,
          style:
              (tabular ? AppTextStyles.moneyTabular : AppTypography.bodySmall)
                  .copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
        ),
      ],
    ),
  );
}

class _ClosedTodayNote extends StatelessWidget {
  final String text;

  const _ClosedTodayNote({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: const BoxDecoration(
      color: AppColors.financeCrossedSurface,
      borderRadius: AppRadius.brMd,
    ),
    child: Row(
      children: [
        const Icon(
          Icons.lock_outline,
          size: AppSpacing.lg,
          color: AppColors.financeCrossedAccent,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.financeCrossedAccent,
            ),
          ),
        ),
      ],
    ),
  );
}
