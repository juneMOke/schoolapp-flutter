import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';

/// Briques communes aux popins de facturation (détail paiement / frais).
///
/// En-tête sombre type AppBar applicative, liseré or-doux, lignes clé/valeur
/// et pied à deux actions responsive — pour un rendu strictement identique
/// d'une popin à l'autre.

/// En-tête sombre : sur-titre or-doux (MAJUSCULES) + titre blanc + pastille
/// optionnelle (statut/solde) + croix de fermeture. Fond Bleu Profond texturé
/// Kuba, comme l'AppBar de la page Facturation (spec §06).
class FinanceModalDarkHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Widget? trailing;
  final VoidCallback onClose;

  const FinanceModalDarkHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.onClose,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
        ),
      ),
      child: Stack(
        children: [
          const KubaPatternLayer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacingM,
              AppDimensions.spacingM,
              AppDimensions.spacingS,
              AppDimensions.spacingM,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        eyebrow.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.orDoux,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.totalAmountLora.copyWith(
                          fontSize: 24,
                          color: AppColors.textOnDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppDimensions.spacingS),
                  trailing!,
                ],
                const SizedBox(width: AppDimensions.spacingXS),
                IconButton(
                  onPressed: onClose,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.textOnDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Liseré or-doux (dégradé horizontal, opacité .55) séparant l'en-tête.
class FinanceModalGoldDivider extends StatelessWidget {
  const FinanceModalGoldDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orDoux.withValues(alpha: 0),
            AppColors.orDoux.withValues(alpha: 0.55),
            AppColors.orDoux.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

/// Donnée d'une ligne clé/valeur d'une popin de facturation.
class FinanceKeyValueRow {
  final IconData icon;
  final String label;
  final String value;

  const FinanceKeyValueRow({
    required this.icon,
    required this.label,
    required this.value,
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
                color: isEmpty ? AppColors.textMuted : AppColors.textPrimary,
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
  final VoidCallback onSecondary;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final double stackBelowWidth;

  const FinanceModalFooter({
    super.key,
    required this.secondaryLabel,
    required this.secondaryIcon,
    required this.onSecondary,
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

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: LayoutBuilder(
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
    );
  }
}
