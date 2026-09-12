import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_holding.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_fee_options.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_fee_picker.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La place des **frais contrôlés** : les pastilles, ou ce qui explique leur
/// absence.
///
/// Une rangée vide a quatre causes, et une seule se répare en réessayant. Les
/// distinguer n'est pas un luxe : « ce niveau n'a pas de frais » est une
/// information sur l'école, « la grille n'est pas descendue » appelle une
/// synchronisation, « le droit manque » n'appelle rien de tout cela, et « la
/// lecture a échoué » n'autorise aucune de ces trois affirmations.
class FeeControlFeeSlot extends StatelessWidget {
  final List<LocalFeeTariff> tariffs;
  final Set<String> selected;
  final bool hasLevel;
  final bool isLoading;
  final bool feeGridMissing;

  /// La lecture locale de la grille n'a pas abouti — à ne jamais confondre avec
  /// une grille vide, qui, elle, est une information.
  final bool loadFailed;

  /// Le titre que l'école donne à chaque nature. Il prime sur le libellé de la
  /// grille : c'est le nom que le tableau de bord écrit aussi.
  final FeeSectionTitlesState sectionTitles;

  final ValueChanged<Set<String>> onChanged;

  /// Rejoue la lecture du niveau courant. Seule porte de sortie de l'échec : au
  /// moins un frais est obligatoire, donc l'écran reste bloqué tant que la
  /// grille n'est pas lue.
  final VoidCallback onRetry;

  const FeeControlFeeSlot({
    super.key,
    required this.tariffs,
    required this.selected,
    required this.hasLevel,
    required this.isLoading,
    required this.feeGridMissing,
    required this.loadFailed,
    required this.onChanged,
    required this.onRetry,
    this.sectionTitles = const FeeSectionTitlesState(),
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Une entrée par NATURE — la maille de la mesure, cf.
    // `buildFeeControlFeeOptions` —, dans l'ordre que l'école donne à ses
    // sections.
    final options = buildFeeControlFeeOptions(tariffs, titles: sectionTitles);

    if (options.isNotEmpty) {
      return RecouvrementFeePicker(
        feeCodes: [for (final option in options) option.feeCode],
        selected: selected,
        enabled: hasLevel && !isLoading,
        // La devise n'est portée que par les natures dont la grille n'en
        // connaît qu'une : les autres n'affichent aucun symbole, et rendent la
        // sélection mixte.
        currencies: {
          for (final option in options)
            if (option.currency != null) option.feeCode: option.currency!,
        },
        // Le titre de section d'abord — le même nom qu'au tableau de bord et
        // que sur la liste de relance —, puis le libellé de la grille quand la
        // nature n'y porte qu'une ligne, puis la nature localisée. La règle vit
        // dans `feeControlFeeCodeLabel`, une fois pour tout le module.
        labels: {
          for (final option in options)
            option.feeCode: feeControlFeeCodeLabel(
              option,
              option.feeCode,
              l10n,
              sectionTitle: sectionTitles.titleOf(option.feeCode),
            ),
        },
        label: l10n.feeControlFeesLabel,
        semanticsLabel: l10n.feeControlFeesA11yLabel,
        onChanged: onChanged,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.feeControlFeesLabel, style: AppTextStyles.tableHeader),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          _message(context, l10n),
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        // Une erreur sans geste de reprise laisse l'opérateur devant une carte
        // qu'il ne peut pas armer. Le bouton n'apparaît que pour l'échec de
        // lecture : « pas de frais à ce niveau » et « grille pas encore
        // descendue » ne se réparent pas en réessayant.
        if (loadFailed && hasLevel && !isLoading) ...[
          const SizedBox(height: AppDimensions.spacingXS),
          EteeloButton.ghost(
            label: l10n.feeControlFeeLoadRetry,
            icon: Icons.refresh,
            onPressed: onRetry,
            // ⚠️ Jamais un `TextButton`/`OutlinedButton` nu ici : le thème du
            // dépôt les veut pleine largeur, et un bouton inline sans
            // `minimumSize` casse la mise en page (contrainte infinie).
            fullWidth: false,
            size: EteeloButtonSize.compact,
          ),
        ],
      ],
    );
  }

  String _message(BuildContext context, AppLocalizations l10n) {
    if (!hasLevel) return l10n.feeControlFeePlaceholder;
    if (isLoading) return l10n.feeControlFeeLoading;
    if (loadFailed) {
      // En tête des trois : les deux autres messages affirment quelque chose
      // sur l'école ou sur la synchronisation, et une lecture qui n'a pas
      // abouti n'autorise ni l'une ni l'autre affirmation.
      return l10n.feeControlFeeLoadFailed;
    }
    if (feeGridMissing) {
      // Le référentiel descend sur `school.read`, mais le serveur en ampute la
      // portion tarifaire quand la session n'a pas `finance.grid.read` :
      // « Synchronisez » promettrait alors une mise à jour déjà faite, qui
      // reviendrait tout aussi caviardée.
      return permissionHolding(context, const [Perm.financeGridRead]) ==
              PermissionHolding.missing
          ? l10n.feeControlFeeGridWithheld
          : l10n.feeControlFeeGridMissing;
    }
    return l10n.feeControlFeeEmptyForLevel;
  }
}
