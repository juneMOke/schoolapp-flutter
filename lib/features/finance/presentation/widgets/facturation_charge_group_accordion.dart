import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_designation.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_grouping.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/fee_progress_parts.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/fee_status_badge.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_pending_sync_badge.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_line.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une nature de frais et ses tranches, repliées sous un en-tête (GF-3).
///
/// Un minerval en sept tranches donnait sept lignes à la suite ; ce qu'on lit
/// d'abord, c'est « où en est cet élève sur le minerval », tranches confondues.
///
/// **Un groupe d'une seule tranche ne se replie pas** : il rend la ligne telle
/// quelle, cliquable vers sa popin. Un accordéon dont le corps répéterait son
/// en-tête ferait payer un geste pour ne rien découvrir.
///
/// **Le clic de l'en-tête plie et déplie, il n'ouvre rien** : il n'existe pas de
/// « détail de nature ». Le détail vit sur la tranche, qui est l'unité d'argent.
class FacturationChargeGroupAccordion extends StatelessWidget {
  final StudentChargeGroup group;

  /// Le titre écrit par l'école, `null` si cet appareil ne le connaît pas
  /// encore — la désignation retombe alors sur la nature localisée.
  final String? schoolTitle;

  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<StudentCharge> onViewChargeRequested;

  const FacturationChargeGroupAccordion({
    super.key,
    required this.group,
    required this.schoolTitle,
    required this.expanded,
    required this.onToggle,
    required this.onViewChargeRequested,
  });

  @override
  Widget build(BuildContext context) {
    if (group.isSingleTranche) {
      final charge = group.charges.single;
      return FacturationChargeLine(
        charge: charge,
        onViewRequested: () => onViewChargeRequested(charge),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final status = group.status;

    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadius.brMd,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GroupHeader(
              label: chargeGroupDesignation(
                group,
                l10n,
                schoolTitle: schoolTitle,
              ),
              status: status,
              group: group,
              expanded: expanded,
              onToggle: onToggle,
            ),
            _AnimatedBody(
              expanded: expanded,
              child: _Tranches(
                group: group,
                onViewChargeRequested: onViewChargeRequested,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// L'en-tête : désignation, badge, chevron, puis **une jauge par devise**.
class _GroupHeader extends StatelessWidget {
  final String label;
  final StudentChargeStatus status;
  final StudentChargeGroup group;
  final bool expanded;
  final VoidCallback onToggle;

  const _GroupHeader({
    required this.label,
    required this.status,
    required this.group,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visuals = status.visuals;
    final remainingByCurrency = {
      for (final entry in group.remaining.entries) entry.currency: entry,
    };

    return InkWell(
      onTap: onToggle,
      borderRadius: AppRadius.brMd,
      hoverColor: AppColors.bleuArdoise.withValues(alpha: 0.06),
      splashColor: AppColors.bleuArdoise.withValues(alpha: 0.10),
      highlightColor: AppColors.bleuArdoise.withValues(alpha: 0.12),
      // `button` + `expanded` disent le GESTE ; le contenu, lui, reste lisible
      // tel qu'il est écrit. Un `ExcludeSemantics` sous une étiquette résumée
      // rendrait le lecteur d'écran muet sur les montants et le statut —
      // exactement ce que la tranche, elle, expose.
      child: Semantics(
        button: true,
        expanded: expanded,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  FeeStatusBadge(
                    label: status.localizedLabel(l10n),
                    visuals: visuals,
                  ),
                  const SizedBox(width: AppDimensions.spacingXS),
                  _Chevron(expanded: expanded),
                ],
              ),
              // Une devise, une jauge. Un remplissage unique sur des dollars
              // ET des francs fabriquerait un pourcentage que personne ne peut
              // vérifier — c'est pourquoi `MoneyBag` n'a pas de total.
              for (final progress in group.progressByCurrency) ...[
                const SizedBox(height: AppDimensions.spacingM),
                FeeProgressBar(progress: progress.ratio, fill: visuals.color),
                const SizedBox(height: AppDimensions.spacingS),
                FeeAmountsRow(
                  expectedLabel:
                      l10n.facturationDetailChargeExpectedAmountColumn,
                  paidLabel: l10n.facturationDetailChargePaidAmountColumn,
                  expected: MoneyFormat.format(progress.expected),
                  paid: MoneyFormat.format(progress.paid),
                  remainingText: _remainingTextOf(
                    remainingByCurrency[progress.expected.currency],
                    l10n,
                  ),
                ),
              ],
              if (group.hasPendingPayment) ...[
                const SizedBox(height: AppDimensions.spacingS),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: FinancePendingSyncBadge(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Rien à dire quand il ne reste rien : « 0 restant » ajouterait un chiffre à
  /// lire pour ne rien apprendre.
  String? _remainingTextOf(Money? remaining, AppLocalizations l10n) {
    if (remaining == null || remaining.isZero) return null;
    return l10n.facturationChargeLineRemainingSuffix(
      MoneyFormat.format(remaining),
    );
  }
}

class _Chevron extends StatelessWidget {
  final bool expanded;

  const _Chevron({required this.expanded});

  @override
  Widget build(BuildContext context) {
    // Reduced-motion : la rotation est un ornement, la flèche doit juste
    // pointer du bon côté.
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return AnimatedRotation(
      turns: expanded ? 0.5 : 0,
      duration: reduceMotion ? Duration.zero : AppMotion.fast,
      curve: AppMotion.outCurve,
      child: const Icon(
        Icons.expand_more_rounded,
        size: AppDimensions.detailHeaderIconSize,
        color: AppColors.textMuted,
      ),
    );
  }
}

/// Le corps déplié, sous un séparateur.
class _Tranches extends StatelessWidget {
  final StudentChargeGroup group;
  final ValueChanged<StudentCharge> onViewChargeRequested;

  const _Tranches({required this.group, required this.onViewChargeRequested});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, color: AppColors.border),
        for (final charge in group.charges)
          FacturationChargeLine(
            key: ValueKey('charge-${charge.id}'),
            charge: charge,
            onViewRequested: () => onViewChargeRequested(charge),
            // Le cadre du groupe entoure déjà : une seconde bordure par tranche
            // ferait des cadres emboîtés à deux pixels d'écart.
            dense: true,
          ),
      ],
    );
  }
}

/// Le pli lui-même.
///
/// `AnimatedSize` plutôt qu'`ExpansionTile` : la ligne doit garder l'anatomie
/// de la tranche (jauge, montants, badges), qu'un `ListTile` ne sait pas rendre.
/// Même patron que `MyCoursesClassAccordion`.
///
/// Le `SizedBox(width: double.infinity)` en état replié n'est pas décoratif : un
/// enfant de largeur nulle ferait s'effondrer la largeur du cadre pendant
/// l'animation de fermeture.
class _AnimatedBody extends StatelessWidget {
  final bool expanded;
  final Widget child;

  const _AnimatedBody({required this.expanded, required this.child});

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return AnimatedSize(
      duration: reduceMotion ? Duration.zero : AppMotion.layout,
      curve: AppMotion.outCurve,
      alignment: Alignment.topCenter,
      child: expanded ? child : const SizedBox(width: double.infinity),
    );
  }
}
