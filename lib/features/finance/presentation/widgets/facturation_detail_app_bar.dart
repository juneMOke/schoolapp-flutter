import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';

/// AppBar de la page de facturation (spec §06).
///
/// Reprend la TopBar applicative — Bleu Profond texturé Kuba — mais la
/// contextualise à l'élève : retour, avatar à initiales, sur-titre
/// « Facturation · {classe} », nom complet, pastille de solde optionnelle à
/// droite et croix de fermeture. Un liseré or-doux la sépare du contenu.
class FacturationDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  static const double _backSize = 42;
  static const double _avatarSize = 42;
  static const double _closeSize = 40;
  static const double _dividerHeight = 2;

  final String fullName;
  final String eyebrow;
  final String firstName;
  final String lastName;
  final String fallbackRoute;

  /// Pastille de solde affichée à droite (cf. [FacturationBalancePill]).
  final Widget? trailing;

  const FacturationDetailAppBar({
    super.key,
    required this.fullName,
    required this.eyebrow,
    required this.firstName,
    required this.lastName,
    required this.fallbackRoute,
    this.trailing,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(AppDimensions.topBarHeight + _dividerHeight);

  void _onExit(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(fallbackRoute);
  }

  String get _initials {
    final letters = [lastName, firstName]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .take(2)
        .map((value) => value.characters.first.toUpperCase())
        .join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.textOnDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: AppDimensions.topBarHeight,
      titleSpacing: AppDimensions.spacingS,
      leadingWidth: AppDimensions.spacingM + _backSize + AppDimensions.spacingS,
      flexibleSpace: const _KubaTopBarBackground(),
      leading: Padding(
        padding: const EdgeInsets.only(left: AppDimensions.spacingM),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _SquareIconButton(
            size: _backSize,
            baseColor: _white(0.10),
            hoverColor: _white(0.08),
            icon: Icons.arrow_back_rounded,
            iconSize: 22,
            onTap: () => _onExit(context),
          ),
        ),
      ),
      title: Row(
        children: [
          _AvatarBadge(initials: _initials, size: _avatarSize),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 2),
                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textOnDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (trailing != null)
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.spacingS),
            child: Center(child: trailing),
          ),
        Padding(
          padding: const EdgeInsets.only(right: AppDimensions.spacingM),
          child: _SquareIconButton(
            size: _closeSize,
            baseColor: _white(0.06),
            hoverColor: _white(0.08),
            icon: Icons.close_rounded,
            iconSize: 20,
            onTap: () => _onExit(context),
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(_dividerHeight),
        child: _GoldDivider(height: _dividerHeight),
      ),
    );
  }

  static Color _white(double opacity) =>
      AppColors.textOnDark.withValues(alpha: opacity);
}

/// Pastille d'état du solde affichée dans l'AppBar sombre (spec §06).
///
/// Dû → fond rouge translucide + bord rouge + « {solde} dû ».
/// À jour → fond vert translucide + « À jour ».
class FacturationBalancePill extends StatelessWidget {
  final bool hasBalance;
  final String label;

  const FacturationBalancePill({
    super.key,
    required this.hasBalance,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = hasBalance
        ? AppColors.feeStatusDue
        : AppColors.feeStatusPaid;
    final Color background = accent.withValues(alpha: hasBalance ? 0.20 : 0.26);
    final Color borderColor = accent.withValues(
      alpha: hasBalance ? 0.50 : 0.40,
    );
    final IconData icon = hasBalance
        ? Icons.account_balance_wallet_outlined
        : Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingXS + 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textOnDark),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            label,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textOnDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fond de la barre : dégradé 100° Bleu Profond → Bleu Ardoise + filigrane Kuba.
class _KubaTopBarBackground extends StatelessWidget {
  const _KubaTopBarBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
        ),
      ),
      child: Stack(fit: StackFit.expand, children: [KubaPatternLayer()]),
    );
  }
}

/// Liseré or-doux (dégradé horizontal, opacité .55) sous la barre.
class _GoldDivider extends StatelessWidget {
  final double height;

  const _GoldDivider({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
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

/// Avatar carré arrondi à initiales sur fond blanc translucide.
class _AvatarBadge extends StatelessWidget {
  final String initials;
  final double size;

  const _AvatarBadge({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.textOnDark.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: AppTextStyles.bodyStrong.copyWith(
          color: AppColors.textOnDark,
          fontSize: 15,
        ),
      ),
    );
  }
}

/// Bouton carré (retour / fermer) sur fond blanc translucide, état survol géré.
class _SquareIconButton extends StatelessWidget {
  final double size;
  final Color baseColor;
  final Color hoverColor;
  final IconData icon;
  final double iconSize;
  final VoidCallback onTap;

  const _SquareIconButton({
    required this.size,
    required this.baseColor,
    required this.hoverColor,
    required this.icon,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: baseColor,
        borderRadius: AppRadius.brSm,
        child: InkWell(
          borderRadius: AppRadius.brSm,
          hoverColor: hoverColor,
          onTap: onTap,
          child: Icon(icon, size: iconSize, color: AppColors.textOnDark),
        ),
      ),
    );
  }
}
