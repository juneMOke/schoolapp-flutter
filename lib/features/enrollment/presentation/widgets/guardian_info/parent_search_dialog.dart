import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_dark_header.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/parent_search_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/parent_search_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/parent_search_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/parent_search_form.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/parent_search_results_list.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Popin "Rechercher un parent" (étape Tuteurs) : recherche locale par numéro
/// OU par identité, sélection immédiate au tap (comme `showEteeloSelectSheet`)
/// — renvoie le parent choisi ou `null` si annulé.
Future<LocalParent?> showParentSearchDialog({required BuildContext context}) {
  return showDialog<LocalParent>(
    context: context,
    barrierColor: AppColors.bleuProfond.withValues(alpha: 0.5),
    builder: (_) => BlocProvider<ParentSearchBloc>(
      create: (_) => getIt<ParentSearchBloc>(),
      child: const _ParentSearchDialog(),
    ),
  );
}

class _ParentSearchDialog extends StatefulWidget {
  const _ParentSearchDialog();

  @override
  State<_ParentSearchDialog> createState() => _ParentSearchDialogState();
}

class _ParentSearchDialogState extends State<_ParentSearchDialog> {
  /// Derniers critères validés : le bouton « Réessayer » de l'état d'erreur
  /// les rejoue tels quels, sans obliger à ressaisir.
  ParentSearchCriteria? _lastCriteria;

  void _search(ParentSearchCriteria criteria) {
    _lastCriteria = criteria;
    context.read<ParentSearchBloc>().add(
      ParentSearchRequested(
        firstName: criteria.firstName,
        lastName: criteria.lastName,
        surname: criteria.surname,
        phoneNumber: criteria.phoneNumber,
      ),
    );
  }

  void _retry() {
    final criteria = _lastCriteria;
    if (criteria != null) _search(criteria);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final inset = size.width <= AppBreakpoints.dataTablePhoneMax
        ? AppDimensions.spacingM
        : AppDimensions.spacingL;

    return Dialog(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.all(inset),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppDimensions.guardianSearchModalMaxWidth,
          maxHeight: size.height * 0.85,
        ),
        child: EteeloDialogBody(
          // Seul l'en-tête reste ancré — titre et croix de fermeture ne
          // doivent jamais fuir vers le haut. Il pèse 86 dp ; sous ce seuil
          // (paysage clavier ouvert, ~63 dp offerts) il déborderait à lui
          // tout seul, et rejoint donc le défilement comme le reste.
          minPinnedHeight: 160,
          header: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EteeloDialogDarkHeader(
                eyebrow: l10n.guardianSearchDialogEyebrow,
                title: l10n.guardianSearchDialogTitle,
                onClose: () => Navigator.of(context).pop(),
              ),
              const EteeloDialogGoldDivider(),
            ],
          ),
          // Les critères DÉFILENT avec les résultats.
          //
          // Ils restaient figés au-dessus tant qu'ils tenaient en quatre
          // champs nus. Depuis la bascule de mode, l'aide contextuelle et les
          // champs requis, le bloc figé pèserait 494 dp (86 d'en-tête + 373
          // de formulaire en mode identité + marges) et il faudrait 726 dp de
          // hauteur offerte pour garder aux résultats leur place minimale —
          // quand la cible, une tablette 10" en paysage, n'en offre que 680.
          // Le figer reviendrait donc à écraser les résultats partout, et à
          // garder pour rien la bascule qui avait rendu le champ intapable
          // (défaut H-1).
          bodyPadding: const EdgeInsets.all(AppDimensions.spacingL),
          footer: const [],
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Seul l'état de chargement compte ici : `buildWhen` évite de
              // reconstruire le formulaire (et sa saisie en cours) à chaque
              // arrivée de résultats.
              BlocBuilder<ParentSearchBloc, ParentSearchState>(
                buildWhen: (prev, curr) =>
                    (prev is ParentSearchLoading) !=
                    (curr is ParentSearchLoading),
                builder: (context, state) => ParentSearchForm(
                  onSearch: _search,
                  isSearching: state is ParentSearchLoading,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingL),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppDimensions.spacingL),
              _buildResults(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(AppLocalizations l10n) {
    return BlocBuilder<ParentSearchBloc, ParentSearchState>(
      builder: (context, state) {
        return switch (state) {
          // Avant toute recherche, la zone reste COMPACTE : lui réserver la
          // hauteur d'une liste pousserait le champ et le bouton hors de la
          // fenêtre à l'ouverture, alors que c'est là que tout se joue.
          ParentSearchInitial() => Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spacingS,
            ),
            child: Text(
              l10n.guardianSearchResultsPlaceholder,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ParentSearchLoading() => EteeloListSkeleton(
            rowCount: 3,
            pillCount: 0,
            semanticsLabel: l10n.guardianSearchDialogTitle,
          ),
          ParentSearchLoaded(:final results) => ParentSearchResultsList(
            results: results,
            onSelected: (parent) => Navigator.of(context).pop(parent),
          ),
          ParentSearchEmpty() => EteeloEmptyResult(
            label: l10n.guardianSearchEmptyTitle,
            description: l10n.guardianSearchEmptyDescription,
            minHeight: AppDimensions.guardianSearchResultsMinHeight,
            cardPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingL,
              vertical: AppDimensions.spacingL,
            ),
            fullWidthCard: true,
          ),
          ParentSearchError(:final message) => EteeloErrorResult(
            type: EteeloErrorType.unknown,
            title: l10n.guardianSearchDialogTitle,
            message: message,
            minHeight: AppDimensions.guardianSearchResultsMinHeight,
            cardPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingL,
              vertical: AppDimensions.spacingL,
            ),
            primaryAction: EteeloButton.primary(
              label: l10n.guardianSearchErrorRetry,
              onPressed: _retry,
            ),
          ),
        };
      },
    );
  }
}
