import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_call_list_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/relance_list_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'aperçu nominatif d'un groupe visé — **on lit, puis on décide d'imprimer**.
///
/// La spec l'exige dans cet ordre, et il n'est pas décoratif : la liste qui sort
/// d'ici se signe et circule. Émettre au clic ferait produire un papier que
/// personne n'a lu, sur une population qu'on n'a pas vérifiée.
///
/// **Rien n'est écrit tant qu'on n'a pas appuyé sur le bouton.** Ouvrir, lire
/// et refermer ne consomme aucun numéro de pièce.
class RecouvrementCallListSheet extends StatelessWidget {
  /// Le groupe visé, tel que le classement le nomme.
  final String groupLabel;

  /// Le critère, en toutes lettres — le papier le portera aussi en sous-titre.
  final String criterionLabel;

  /// Ce que fait le bouton d'édition. `null` désarme le bouton : c'est ce qui
  /// se passe pendant un rendu, ou pendant l'attente qu'un 429 a imposée.
  final VoidCallback? onEmit;

  const RecouvrementCallListSheet({
    super.key,
    required this.groupLabel,
    required this.criterionLabel,
    required this.onEmit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.recouvrementCallListMaxWidth,
          maxHeight: AppDimensions.recouvrementCallListMaxHeight,
        ),
        child: BlocBuilder<RecouvrementCallListCubit, RecouvrementCallListState>(
          builder: (context, state) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                groupLabel: groupLabel,
                criterionLabel: criterionLabel,
                count: state.rows.length,
              ),
              Flexible(child: _Body(state: state)),
              _Footer(
                // Rien à éditer tant que la liste n'a pas abouti, ou si elle
                // est vide : un bouton qui produirait un papier sans ligne
                // n'aurait rien à faire signer.
                onEmit:
                    state.status == EnrollmentLoadStatus.success &&
                        state.rows.isNotEmpty
                    ? onEmit
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String groupLabel;
  final String criterionLabel;
  final int count;

  const _Header({
    required this.groupLabel,
    required this.criterionLabel,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recouvrementCallListTitle(groupLabel),
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            l10n.recouvrementCallListSubtitle(count, criterionLabel),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final RecouvrementCallListState state;

  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (state.status == EnrollmentLoadStatus.loading ||
        state.status == EnrollmentLoadStatus.initial) {
      // Le squelette défile comme la liste qu'il annonce : ses six lignes
      // dépassent la hauteur offerte en paysage, et une colonne figée y
      // déborderait de plus de cent pixels.
      return const SingleChildScrollView(
        padding: EdgeInsets.all(AppDimensions.spacingM),
        child: EteeloListSkeleton(rowCount: 6, showAvatar: false),
      );
    }

    if (state.rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: Center(
          child: Text(
            l10n.recouvrementCallListEmpty,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final hasUnnamed = state.rows.any((row) => row.displayName == null);

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
      children: [
        const SizedBox(height: AppDimensions.spacingS),
        const _ColumnHeader(),
        for (final row in state.rows) _StudentRow(row: row),
        if (hasUnnamed) ...[
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            l10n.recouvrementCallListUnnamedNote,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
        const SizedBox(height: AppDimensions.spacingS),
      ],
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget cell(String text, int flex, {TextAlign align = TextAlign.start}) =>
        Expanded(
          flex: flex,
          child: Text(text, style: AppTextStyles.tableHeader, textAlign: align),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Row(
        children: [
          cell(l10n.recouvrementCallListStudent, 4),
          cell(l10n.recouvrementCallListDue, 3, align: TextAlign.end),
          cell(l10n.recouvrementCallListPaid, 3, align: TextAlign.end),
          cell(l10n.recouvrementCallListRemaining, 3, align: TextAlign.end),
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final RecouvrementCallListRow row;

  const _StudentRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final named = row.displayName;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              // Un élève que les inscriptions ne connaissent plus garde sa
              // dette : on l'écrit par son identifiant plutôt que de le retirer
              // d'une liste de relance en silence.
              named ??
                  l10n.recouvrementCallListUnnamed(
                    row.studentId.length <= 8
                        ? row.studentId
                        : row.studentId.substring(0, 8),
                  ),
              style: named == null
                  ? AppTextStyles.body.copyWith(color: AppColors.textMuted)
                  : AppTextStyles.body,
            ),
          ),
          _amount(row.expected, 3),
          _amount(row.paid, 3),
          _amount(row.remaining, 3),
        ],
      ),
    );
  }

  /// Une ligne par devise, empilées. **Jamais de total croisé** : en sélection
  /// mixte, dû, payé et reste s'écrivent chacun sur deux lignes.
  static Widget _amount(MoneyBag bag, int flex) => Expanded(
    flex: flex,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final entry in bag.entries)
          Text(
            MoneyFormat.format(entry),
            style: AppTextStyles.moneyTabular,
            textAlign: TextAlign.end,
          ),
      ],
    ),
  );
}

class _Footer extends StatelessWidget {
  final VoidCallback? onEmit;

  const _Footer({required this.onEmit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<RelanceListCubit, RelanceListState>(
      buildWhen: (prev, curr) => prev.status != curr.status,
      builder: (context, relance) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.recouvrementCallListClose),
            ),
            const SizedBox(width: AppDimensions.spacingS),
            FilledButton.icon(
              // ⚠️ Sans ce `minimumSize`, la modale entière n'a plus de taille.
              // Le thème donne aux `FilledButton` une largeur minimale infinie
              // (pensée pour les CTA pleine largeur) ; posé en enfant non-flex
              // d'un `Row`, qui offre déjà une largeur non bornée, le bouton
              // lève « BoxConstraints forces an infinite width » — l'erreur est
              // avalée au layout, et c'est le premier clic suivant qui éclate
              // sur « Cannot hit test a render box with no size ».
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppDimensions.minTouchTarget),
              ),
              // Le bouton se désarme pendant le rendu ET pendant l'attente
              // qu'un 429 a imposée : un second appui lancerait un second rendu
              // que le serveur refuserait.
              onPressed: relance.isBusy ? null : onEmit,
              icon: relance.status == RelanceListStatus.preparing
                  ? const SizedBox(
                      width: AppDimensions.recouvrementCallListSpinner,
                      height: AppDimensions.recouvrementCallListSpinner,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(
                relance.status == RelanceListStatus.preparing
                    ? l10n.recouvrementRelanceListPreparing
                    : l10n.recouvrementCallListEmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
