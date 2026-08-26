import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// Ligne discrète « ☎ numéro du payeur », sous le nom.
///
/// Le numéro ne se met JAMAIS sur la même ligne que la date : cette ligne-là
/// tronque déjà à l'ellipse sur un téléphone étroit, et un numéro tronqué
/// (`+2438169…`) ne se lit plus — il se recopie faux. Une ligne à lui,
/// affichée seulement quand il y a quelque chose à montrer.
///
/// [phoneNumber] nul ou vide → rien du tout. C'est le cas de tout versement
/// antérieur au palier v28 et de tout versement encaissé sur un autre poste :
/// dans une LISTE, répéter « numéro inconnu » à chaque ligne ne renseigne
/// personne et noie ce qui compte. Les écrans de détail, eux, le disent
/// explicitement — on y est venu pour savoir.
class FinancePayerPhoneLine extends StatelessWidget {
  final String? phoneNumber;

  const FinancePayerPhoneLine({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    final number = phoneNumber?.trim() ?? '';
    if (number.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          const Icon(
            Icons.phone_outlined,
            size: 13,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Flexible(
            child: Text(
              number,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
