import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/helpers/phone_number_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Pièces internes de [EteeloPhoneInput] : la case indicatif et le filtre de
/// saisie de la partie nationale.

/// Filtre de la partie nationale : chiffres seuls, `0` de tête du plan
/// national retiré, longueur bornée par le pays.
///
/// Le `0` doit sauter AVANT le plafond de longueur : sans cela, l'habitude
/// congolaise (`0816939060`) remplirait le champ avec `081693906` — neuf
/// chiffres d'apparence correcte, dernier chiffre refusé en silence, et un
/// message d'erreur qui réclame « 9 chiffres » alors qu'ils sont là.
class NationalNumberInputFormatter extends TextInputFormatter {
  final PhoneCountry country;

  const NationalNumberInputFormatter(this.country);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = PhoneNumberFormat.digitsOnly(newValue.text);
    while (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length > country.nationalLength) {
      digits = digits.substring(0, country.nationalLength);
    }
    if (digits == newValue.text) return newValue;
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

/// Filtre du mode « numéro étranger » : la valeur reste entière, on écarte
/// seulement ce qu'un numéro ne peut pas contenir.
class ForeignNumberInputFormatter extends TextInputFormatter {
  const ForeignNumberInputFormatter();

  static final RegExp _allowed = RegExp(r'[^0-9+()\- ]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = newValue.text.replaceAll(_allowed, '');
    if (cleaned == newValue.text) return newValue;
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}

/// Case indicatif : drapeau + code international, séparée du champ par un
/// filet vertical. Non interactive en v1 (le pays n'est pas modifiable) :
/// seul le focus du champ suit le tap, câblé par [EteeloTextInput].
class PhoneDialCodeBox extends StatelessWidget {
  final PhoneCountry country;
  final String? semanticLabel;

  /// Numéro d'un autre pays : l'indicatif vit alors dans le champ lui-même,
  /// la case ne peut plus l'annoncer.
  final bool foreign;

  const PhoneDialCodeBox({
    super.key,
    required this.country,
    this.semanticLabel,
    this.foreign = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      readOnly: true,
      // Sans libellé de remplacement, on garde la lecture naturelle du
      // contenu : masquer les deux à la fois priverait le champ de tout
      // repère de pays.
      excludeSemantics: semanticLabel != null,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceAlt,
          border: Border(right: BorderSide(color: AppColors.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: foreign
                ? const [
                    Icon(
                      Icons.public,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ]
                : [
                    // Le drapeau n'est pas rendu par toutes les plateformes :
                    // le code international reste donc toujours lisible.
                    Text(
                      country.flagEmoji,
                      style: AppTypography.bodyMedium.copyWith(height: 1.3),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      country.dialCode,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
