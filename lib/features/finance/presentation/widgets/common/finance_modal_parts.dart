import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';

/// Briques communes aux popins de facturation (détail paiement / frais) :
/// lignes clé/valeur et pied à deux actions responsive — pour un rendu
/// strictement identique d'une popin à l'autre.
///
/// L'en-tête sombre et son liseré ont rejoint le socle partagé
/// (`EteeloDialogDarkHeader`, `EteeloDialogGoldDivider`) : ils servent
/// désormais au-delà de Facturation.

/// Donnée d'une ligne clé/valeur d'une popin de facturation.
class FinanceKeyValueRow {
  final IconData icon;
  final String label;
  final String value;

  /// Barre la valeur : ce qu'elle désigne n'a plus cours — un numéro de pièce
  /// que l'établissement a retiré, par exemple.
  ///
  /// La rature ne porte jamais l'information seule : l'appelant doit doubler
  /// d'une phrase qui dit ce qui a été retiré, et pourquoi.
  final bool isStruckThrough;

  const FinanceKeyValueRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isStruckThrough = false,
  });
}

/// Lignes clé/valeur encadrées et séparées par un filet : icône bleu-ardoise +
/// label allégé à gauche · valeur à l'extrême droite (vide → « — »).
class FinanceKeyValueRows extends StatelessWidget {
  final List<FinanceKeyValueRow> rows;

  const FinanceKeyValueRows({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _KeyValueRow(data: rows[i]),
            if (i < rows.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final FinanceKeyValueRow data;

  const _KeyValueRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final isEmpty = data.value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS + 2,
      ),
      child: Row(
        children: [
          Icon(data.icon, size: 18, color: AppColors.bleuArdoise),
          const SizedBox(width: AppDimensions.spacingS),
          Flexible(
            child: Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Text(
              isEmpty ? '—' : data.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyStrong.copyWith(
                color: isEmpty || data.isStruckThrough
                    ? AppColors.textMuted
                    : AppColors.textPrimary,
                decoration: data.isStruckThrough
                    ? TextDecoration.lineThrough
                    : null,
                decorationColor: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pied à deux actions (secondaire + primaire). Empile verticalement sous une
/// largeur donnée pour ne pas serrer/déborder les libellés longs sur mobile.
class FinanceModalFooter extends StatelessWidget {
  final String secondaryLabel;
  final IconData secondaryIcon;

  /// Nullable : `null` rend l'action secondaire inerte. Sert aux actions qui ne
  /// peuvent pas encore aboutir (reçu d'un encaissement non synchronisé) —
  /// mieux vaut un bouton visiblement éteint, accompagné de [secondaryHint],
  /// qu'un bouton qui échoue à chaque appui.
  final VoidCallback? onSecondary;

  /// Explication affichée sous le pied quand l'action secondaire est inerte.
  final String? secondaryHint;

  final String primaryLabel;
  final IconData primaryIcon;

  /// Nullable : `null` rend l'action primaire désactivée (ex. gel READ_ONLY
  /// ADR-010) tout en laissant la secondaire (navigation) libre.
  final VoidCallback? onPrimary;
  final double stackBelowWidth;

  const FinanceModalFooter({
    super.key,
    required this.secondaryLabel,
    required this.secondaryIcon,
    required this.onSecondary,
    this.secondaryHint,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    this.stackBelowWidth = 420,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = EteeloButton.secondary(
      label: secondaryLabel,
      icon: secondaryIcon,
      onPressed: onSecondary,
    );
    final primary = EteeloButton.primary(
      label: primaryLabel,
      icon: primaryIcon,
      onPressed: onPrimary,
    );

    // N'a de sens que si l'action secondaire est effectivement inerte : sinon
    // l'explication contredirait un bouton actif.
    final hint = onSecondary == null ? secondaryHint?.trim() : null;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < stackBelowWidth) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    secondary,
                    const SizedBox(height: AppDimensions.spacingS),
                    primary,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: secondary),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(child: primary),
                ],
              );
            },
          ),
          if (hint != null && hint.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
