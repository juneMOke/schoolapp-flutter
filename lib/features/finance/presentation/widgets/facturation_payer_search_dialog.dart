import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_dark_header.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_payer_identity.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payer_search_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payer_search_event.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payer_search_state.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payer_search_form.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payer_search_results_list.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Popin « Choisir un payeur » (modale d'encaissement) : propose d'emblée les
/// payeurs déjà connus pour cet élève, et permet d'en chercher d'autres par
/// numéro OU par identité. Renvoie le payeur choisi, ou `null` si annulé.
///
/// Lecture 100% locale : elle doit répondre sur une tablette coupée du réseau,
/// puisque l'encaissement qu'elle sert, lui, aboutit hors ligne.
Future<LocalPayerIdentity?> showFacturationPayerSearchDialog({
  required BuildContext context,
  required String studentId,
}) {
  return showDialog<LocalPayerIdentity>(
    context: context,
    barrierColor: AppColors.bleuProfond.withValues(alpha: 0.5),
    builder: (_) => BlocProvider<PayerSearchBloc>(
      create: (_) =>
          getIt<PayerSearchBloc>()..add(PayerSuggestionsRequested(studentId)),
      child: const _FacturationPayerSearchDialog(),
    ),
  );
}

class _FacturationPayerSearchDialog extends StatefulWidget {
  const _FacturationPayerSearchDialog();

  @override
  State<_FacturationPayerSearchDialog> createState() =>
      _FacturationPayerSearchDialogState();
}

class _FacturationPayerSearchDialogState
    extends State<_FacturationPayerSearchDialog> {
  /// Derniers critères validés : « Réessayer » les rejoue tels quels, sans
  /// obliger à ressaisir.
  PayerSearchCriteria? _lastCriteria;

  void _search(PayerSearchCriteria criteria) {
    _lastCriteria = criteria;
    context.read<PayerSearchBloc>().add(
      PayerSearchRequested(
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
          maxWidth: AppDimensions.facturationPayerSearchModalMaxWidth,
          maxHeight: size.height * 0.85,
        ),
        child: EteeloDialogBody(
          // Seul l'en-tête reste ancré. Il pèse 86 dp ; sous ce seuil (paysage
          // clavier ouvert) il déborderait à lui seul et rejoint donc le
          // défilement comme le reste. Les critères défilent avec les
          // résultats — les figer écraserait la liste sur une tablette 10".
          minPinnedHeight: 160,
          header: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EteeloDialogDarkHeader(
                eyebrow: l10n.facturationPayerSearchDialogEyebrow,
                title: l10n.facturationPayerSearchDialogTitle,
                onClose: () => Navigator.of(context).pop(),
              ),
              const EteeloDialogGoldDivider(),
            ],
          ),
          bodyPadding: const EdgeInsets.all(AppDimensions.spacingL),
          footer: const [],
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Seul l'état de chargement compte ici : `buildWhen` évite de
              // reconstruire le formulaire (et sa saisie en cours) à chaque
              // arrivée de résultats.
              BlocBuilder<PayerSearchBloc, PayerSearchState>(
                buildWhen: (prev, curr) =>
                    (prev is PayerSearchLoading) !=
                    (curr is PayerSearchLoading),
                builder: (context, state) => FacturationPayerSearchForm(
                  onSearch: _search,
                  isSearching: state is PayerSearchLoading,
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
    return BlocBuilder<PayerSearchBloc, PayerSearchState>(
      builder: (context, state) {
        return switch (state) {
          // Rien à proposer et rien de cherché : la zone reste COMPACTE. Lui
          // réserver la hauteur d'une liste pousserait les champs et le bouton
          // hors de la fenêtre à l'ouverture, là où tout se joue.
          PayerSearchInitial() => Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spacingS,
            ),
            child: Text(
              l10n.facturationPayerSearchResultsPlaceholder,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          PayerSearchLoading() => EteeloListSkeleton(
            rowCount: 3,
            pillCount: 0,
            semanticsLabel: l10n.facturationPayerSearchDialogTitle,
          ),
          PayerSearchLoaded(:final results, :final isSuggestion) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isSuggestion
                    ? l10n.facturationPayerSearchSuggestionsTitle
                    : l10n.facturationPayerSearchResultsTitle,
                style: AppTextStyles.badge.copyWith(
                  color: AppColors.terreCuite,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              FacturationPayerSearchResultsList(
                results: results,
                onSelected: (payer) => Navigator.of(context).pop(payer),
              ),
            ],
          ),
          PayerSearchEmpty() => EteeloEmptyResult(
            label: l10n.facturationPayerSearchEmptyTitle,
            description: l10n.facturationPayerSearchEmptyDescription,
            minHeight: AppDimensions.facturationPayerSearchResultsMinHeight,
            cardPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingL,
              vertical: AppDimensions.spacingL,
            ),
            fullWidthCard: true,
          ),
          PayerSearchError(:final message) => EteeloErrorResult(
            type: EteeloErrorType.unknown,
            title: l10n.facturationPayerSearchDialogTitle,
            message: message,
            minHeight: AppDimensions.facturationPayerSearchResultsMinHeight,
            cardPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingL,
              vertical: AppDimensions.spacingL,
            ),
            primaryAction: EteeloButton.primary(
              label: l10n.facturationPayerSearchErrorRetry,
              onPressed: _retry,
            ),
          ),
        };
      },
    );
  }
}
