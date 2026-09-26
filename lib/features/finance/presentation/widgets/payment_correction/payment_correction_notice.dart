import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// Une phrase d'état sous l'identité du payeur, dans le détail d'un versement :
/// annulation en attente, correction refusée, versement remplaçant.
///
/// Jamais la seule couleur : l'icône et la phrase disent ce que la teinte ne
/// peut pas dire.
class PaymentCorrectionNotice extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const PaymentCorrectionNotice({
    super.key,
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppDimensions.spacingXS),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
