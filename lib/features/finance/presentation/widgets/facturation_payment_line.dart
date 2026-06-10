import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ligne d'un versement (spec §09).
///
/// Médaillon « billet » vert, identité du payeur (Nom Post-nom Prénom — une
/// personne, pas l'élève), méta (date · moyen), montant en vert préfixé « + ».
/// Tout l'élément est cliquable et mène au détail du paiement ; survol = bord
/// or-bleu, fond state-hover, légère élévation et chevron bleu-ardoise.
class FacturationPaymentLine extends StatefulWidget {
  final Payment payment;
  final VoidCallback onTap;

  const FacturationPaymentLine({
    super.key,
    required this.payment,
    required this.onTap,
  });

  @override
  State<FacturationPaymentLine> createState() => _FacturationPaymentLineState();
}

class _FacturationPaymentLineState extends State<FacturationPaymentLine> {
  static const double _medallionSize = 40;
  bool _hovered = false;

  String _payerFullName(AppLocalizations l10n) {
    final fullName = [
      widget.payment.payerLastName,
      widget.payment.payerMiddleName ?? '',
      widget.payment.payerFirstName,
    ].map((value) => value.trim()).where((value) => value.isNotEmpty).join(' ');
    return fullName.isEmpty ? l10n.facturationDetailUnknownValue : fullName;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = MaterialLocalizations.of(
      context,
    ).formatShortDate(widget.payment.paidAt);
    final amount = formatMonetaryAmountWithCurrency(
      amount: widget.payment.amountInCents / 100,
      currency: widget.payment.currency,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (value) => setState(() => _hovered = value),
        borderRadius: AppRadius.brMd,
        child: AnimatedContainer(
          duration: AppMotion.micro,
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hovered ? -1 : 0, 0),
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.stateHover : AppColors.surfaceRaised,
            borderRadius: AppRadius.brMd,
            border: Border.all(
              color: _hovered ? AppColors.billingHelpBorder : AppColors.border,
            ),
            boxShadow: _hovered
                ? const [
                    BoxShadow(
                      color: AppColors.financeDetailShadow,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              const _PaymentMedallion(size: _medallionSize),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _payerFullName(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _PaymentMeta(
                      date: date,
                      method: l10n.facturationPaymentMethodCash,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                '+ $amount',
                style: AppTextStyles.moneyTabular.copyWith(
                  color: AppColors.feeStatusPaid,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingXS),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: _hovered ? AppColors.bleuArdoise : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Médaillon « billet » vert (spec §09).
class _PaymentMedallion extends StatelessWidget {
  final double size;

  const _PaymentMedallion({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.billingPaymentMedallionSoft,
        borderRadius: AppRadius.brMd,
      ),
      child: const Icon(
        Icons.payments_outlined,
        size: 20,
        color: AppColors.feeStatusPaid,
      ),
    );
  }
}

/// Méta d'un versement : calendrier + date · moyen.
class _PaymentMeta extends StatelessWidget {
  final String date;
  final String method;

  const _PaymentMeta({required this.date, required this.method});

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.caption.copyWith(color: AppColors.textMuted);
    return Row(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 13,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppDimensions.spacingXS),
        Flexible(
          child: Text(
            '$date · $method',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}
