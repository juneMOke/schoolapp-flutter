import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Habillage de l'en-tête d'une [BiToneSectionCard].
///
/// [light] est le défaut — le bi-ton pâle historique, employé par tous les
/// écrans qui composent cette carte. [brand] est le **dégradé de marque**, le
/// même que l'accueil et le bandeau d'effectif : il ouvre un écran de travail
/// et annonce « ici, on saisit ».
enum BiToneHeaderVariant { light, brand }

class BiToneSectionCard extends StatelessWidget {
  static const double _headerRailWidth = 4;

  /// Voile du médaillon sur dégradé, et de son liseré.
  static const double brandMedallionVeil = 0.14;
  static const double brandMedallionBorderVeil = 0.20;
  static const double _headerIconSize = 36;
  static const double _headerIconGlyphSize = 18;
  static const double _headerIconRadius = 10;
  static const double _headerIconShadowBlur = 10;
  static const double _headerIconShadowOffsetY = 4;
  static const double _headerStackMinWidth =
      AppBreakpoints.enrollmentTableGridSwitchMax / 2;

  static const List<Color> _headerGradient = [
    Color(0xFFF5F8FB),
    Color(0xFFFBF6EF),
  ];

  /// ⚠️ Le filet bas reste **neutre**, même sur une carte teintée.
  ///
  /// Le faire suivre [borderColor] serait plus cohérent — un séparateur gris
  /// entre un en-tête pâle et un corps coloré se remarque. Mais **sept
  /// appelants déclarent déjà un `borderColor`** sans rien demander de tel :
  /// `classes_organisation_split_states`, `..._pending_distribution_card`,
  /// `facturation_detail_page`, `facturation_create_payment_page`,
  /// `first_registration_search_form` et `status_badge`. Le changement aurait
  /// donc retouché l'en-tête de sept écrans au passage.
  ///
  /// La règle de ce chantier prime : un composant partagé ne change pas de
  /// rendu par défaut. Si la cohérence du filet devient gênante, elle se
  /// traitera par une option explicite, écran par écran.
  static const BoxDecoration _headerDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: _headerGradient,
    ),
    border: Border(bottom: BorderSide(color: AppColors.border)),
    borderRadius: BorderRadius.vertical(top: AppRadius.card),
  );

  final Widget child;
  final Widget? header;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color accentColor;
  final EdgeInsetsGeometry bodyPadding;
  final EdgeInsetsGeometry headerPadding;
  final bool showShadow;
  final Color surfaceColor;

  /// Bord de la carte. `null` → [AppColors.border], le comportement historique.
  /// Un corps teinté a besoin d'un bord dérivé de sa propre teinte, sans quoi
  /// il flotte sur le fond de page.
  final Color? borderColor;

  /// Habillage de l'en-tête. Le défaut ne bouge pas d'un pixel.
  final BiToneHeaderVariant headerVariant;

  const BiToneSectionCard({
    super.key,
    required this.child,
    this.header,
    this.title,
    this.subtitle,
    this.icon,
    this.borderColor,
    this.headerVariant = BiToneHeaderVariant.light,
    this.accentColor = AppColors.bleuArdoise,
    this.bodyPadding = const EdgeInsets.all(AppSpacing.xl - 2),
    this.headerPadding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl - 2,
      vertical: AppSpacing.lg + 2,
    ),
    this.showShadow = true,
    this.surfaceColor = AppColors.surfaceRaised,
  });

  bool get _hasStructuredHeader =>
      title != null || subtitle != null || icon != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: showShadow ? AppElevation.shadowCard : null,
      ),
      clipBehavior: headerVariant == BiToneHeaderVariant.brand
          ? Clip.antiAlias
          : Clip.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) _buildCustomHeader(header!),
          if (header == null && _hasStructuredHeader) _buildStructuredHeader(),
          Padding(padding: bodyPadding, child: child),
        ],
      ),
    );
  }

  bool get _isBrand => headerVariant == BiToneHeaderVariant.brand;

  /// Le dégradé de marque — **105°**, comme l'accueil et le bandeau
  /// d'effectif. La maquette de cet écran était restée à 104° pour des raisons
  /// historiques ; la spec demande explicitement de l'aligner.
  static const BoxDecoration _brandHeaderDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment(-1, -0.26),
      end: Alignment(1, 0.26),
      colors: [
        AppColors.bleuProfond,
        AppColors.bleuArdoise,
        AppColors.bleuArdoiseLight,
      ],
      stops: [0, 0.78, 1],
    ),
  );

  Widget _buildCustomHeader(Widget content) {
    if (!_isBrand) {
      return Container(
        width: double.infinity,
        padding: headerPadding,
        decoration: _headerDecoration,
        child: content,
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(decoration: _brandHeaderDecoration),
          ),
          Padding(padding: headerPadding, child: content),
          // Filet d'or en tête — la signature que partagent les trois bandeaux
          // de l'application.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: AppDimensions.insBannerFiletHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.orDoux, Color(0x00D9A24E)],
                  stops: [0, AppDimensions.insSectionFiletFadeStop],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructuredHeader() {
    return _buildCustomHeader(
      LayoutBuilder(
        builder: (context, constraints) {
          final shouldStack = constraints.maxWidth < _headerStackMinWidth;

          if (shouldStack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderLeading(),
                const SizedBox(height: AppSpacing.md),
                _buildHeaderText(),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderLeading(),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _buildHeaderText()),
            ],
          );
        },
      ),
    );
  }

  /// Sur dégradé, le médaillon devient un **voile** et son glyphe passe en or :
  /// un aplat d'accent sur une surface déjà colorée ne se détacherait plus. Le
  /// filet vertical disparaît alors — il n'a de sens que sur un en-tête pâle.
  Widget _buildHeaderLeading() {
    if (_isBrand) {
      return ExcludeSemantics(
        child: Container(
          width: _headerIconSize,
          height: _headerIconSize,
          decoration: BoxDecoration(
            color: AppColors.blancCasse.withValues(alpha: brandMedallionVeil),
            borderRadius: BorderRadius.circular(_headerIconRadius),
            border: Border.all(
              color: AppColors.blancCasse.withValues(
                alpha: brandMedallionBorderVeil,
              ),
            ),
          ),
          child: Icon(
            icon ?? Icons.search_rounded,
            size: _headerIconGlyphSize,
            color: AppColors.orDoux,
          ),
        ),
      );
    }

    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _headerRailWidth,
            height: _headerIconSize,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: AppRadius.brPill,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: _headerIconSize,
            height: _headerIconSize,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(_headerIconRadius),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: _headerIconShadowBlur,
                  offset: const Offset(0, _headerIconShadowOffsetY),
                ),
              ],
            ),
            child: Icon(
              icon ?? Icons.search_rounded,
              size: _headerIconGlyphSize,
              color: AppColors.textOnDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Semantics(
            header: true,
            child: Text(
              title!,
              style: AppTypography.titleMedium.copyWith(
                color: _isBrand ? AppColors.blancCasse : AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        if (subtitle != null) ...[
          if (title != null) const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            // Sur dégradé, l'encre secondaire est OPAQUE : un blanc
            // transparent y a un ratio qui dépend du point où on le mesure,
            // donc invérifiable (§12).
            style: AppTypography.bodySmall.copyWith(
              color: _isBrand
                  ? AppColors.listeInkSubtitle
                  : AppColors.textMuted,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
