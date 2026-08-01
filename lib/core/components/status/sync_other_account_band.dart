import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/core/offline/outbox_author_directory.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bande **en lecture seule** : ce qui reste en file au nom d'un autre compte.
///
/// Sans elle, la garde d'attribution du moteur serait une protection invisible :
/// les écritures d'un collègue ne partent plus (tant mieux, elles seraient
/// refusées) mais la pastille affiche « à envoyer » sans que personne ne
/// comprenne pourquoi la file ne se vide pas. On explique donc l'attente —
/// nombre, ancienneté, et nom du collègue — **sans jamais révéler le contenu**
/// de ses écritures.
///
/// Aucune action offerte : ni rejouer (ce serait le pousser sous le mauvais
/// jeton, exactement ce qu'on vient d'empêcher), ni abandonner (supprimer une
/// entrée détruirait sa clé d'idempotence et laisserait l'agrégat métier bloqué
/// en `PENDING_SYNC` — cf. la doctrine écrite dans `OutboxDao`).
class SyncOtherAccountBand extends StatelessWidget {
  final OtherAuthorsPending others;
  final List<OutboxAuthorIdentity?> authors;

  const SyncOtherAccountBand({
    super.key,
    required this.others,
    required this.authors,
  });

  /// « Marie Kabila » → « Marie K. ». Le nom complet d'un collègue n'apporte
  /// rien à la compréhension de l'attente ; l'initiale suffit à lever
  /// l'ambiguïté entre deux prénoms identiques.
  static String? shortNameOf(OutboxAuthorIdentity? identity) {
    if (identity == null || identity.isBlank) return null;
    final first = identity.firstName.trim();
    final last = identity.lastName.trim();
    if (first.isEmpty) return last;
    if (last.isEmpty) return first;
    return '$first ${last.substring(0, 1).toUpperCase()}.';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Un seul auteur nommé : on le nomme. Plusieurs (ou inconnu) : formulation
    // anonyme — empiler trois noms dans une bande d'explication la rendrait
    // moins lisible que le fait qu'elle veut transmettre.
    final singleName = authors.length == 1 ? shortNameOf(authors.first) : null;
    final headline = singleName == null
        ? l10n.syncErrorsOtherAccountAnonymous(others.count)
        : l10n.syncErrorsOtherAccountNamed(others.count, singleName);

    final oldestMs = others.oldestCreatedAt;
    final oldest = oldestMs == null
        ? null
        : l10n.syncErrorsOtherAccountOldest(
            DateTime.fromMillisecondsSinceEpoch(oldestMs),
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCool,
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.syncErrorsOtherAccountTitle,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(headline, style: AppTypography.bodyMedium),
          if (oldest != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              oldest,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.syncErrorsOtherAccountHint,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
