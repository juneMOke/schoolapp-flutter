import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/parent_search_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/parent_search_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/parent_search_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/first_letter_uppercase_text_input_formatter.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Popin "Rechercher un parent" (étape Tuteurs) : recherche locale par
/// nom/postnom/prénom et/ou téléphone, sélection immédiate au tap (comme
/// `showEteeloSelectSheet`) — renvoie le parent choisi ou `null` si annulé.
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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool get _canSearch =>
      _firstNameController.text.trim().isNotEmpty ||
      _lastNameController.text.trim().isNotEmpty ||
      _surnameController.text.trim().isNotEmpty ||
      _phoneController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _firstNameController,
      _lastNameController,
      _surnameController,
      _phoneController,
    ]) {
      c.addListener(_onFieldChanged);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameController,
      _lastNameController,
      _surnameController,
      _phoneController,
    ]) {
      c.removeListener(_onFieldChanged);
      c.dispose();
    }
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _search() {
    if (!_canSearch) return;
    context.read<ParentSearchBloc>().add(
      ParentSearchRequested(
        firstName: _trimmedOrNull(_firstNameController.text),
        lastName: _trimmedOrNull(_lastNameController.text),
        surname: _trimmedOrNull(_surnameController.text),
        phoneNumber: _trimmedOrNull(_phoneController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final maxHeight = size.height * 0.85;
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
          maxHeight: maxHeight,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // `Dialog` retire les `viewInsets` du clavier à la hauteur offerte :
            // en paysage il n'en reste qu'une centaine de dp, quand l'en-tête et
            // le formulaire figés en coûtent trois fois plus. Sous ce seuil, les
            // critères rejoignent le défilement des résultats.
            final pinsForm =
                constraints.maxHeight >=
                AppBreakpoints.guardianSearchPinnedFormMinHeight;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(l10n),
                const Divider(height: 1, color: AppColors.border),
                if (pinsForm) ...[
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingL),
                    child: _buildSearchForm(l10n),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                ],
                // Flexible + scroll : la zone résultats (squelette/vide/erreur/
                // liste) doit pouvoir se réduire OU défiler sans jamais
                // déborder, le budget vertical restant dépendant du nombre de
                // lignes prises par le formulaire de recherche (Wrap
                // responsive).
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.spacingL),
                    child: pinsForm
                        ? _buildResults(l10n)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSearchForm(l10n),
                              const SizedBox(height: AppDimensions.spacingL),
                              const Divider(height: 1, color: AppColors.border),
                              const SizedBox(height: AppDimensions.spacingL),
                              _buildResults(l10n),
                            ],
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.guardianSearchDialogTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.sectionTitle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchForm(AppLocalizations l10n) {
    final nameFormatters = <TextInputFormatter>[
      const FirstLetterUppercaseTextInputFormatter(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.guardianSearchHint,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Wrap(
          spacing: AppDimensions.spacingM,
          runSpacing: AppDimensions.spacingM,
          children: [
            SizedBox(
              width: 200,
              child: EteeloTextInput(
                label: l10n.firstName,
                controller: _firstNameController,
                inputFormatters: nameFormatters,
                onSubmitted: (_) => _search(),
              ),
            ),
            SizedBox(
              width: 200,
              child: EteeloTextInput(
                label: l10n.lastName,
                controller: _lastNameController,
                inputFormatters: nameFormatters,
                onSubmitted: (_) => _search(),
              ),
            ),
            SizedBox(
              width: 200,
              child: EteeloTextInput(
                label: l10n.surname,
                controller: _surnameController,
                inputFormatters: nameFormatters,
                onSubmitted: (_) => _search(),
              ),
            ),
            SizedBox(
              width: 200,
              child: EteeloTextInput(
                label: l10n.phoneNumberLabel,
                controller: _phoneController,
                keyboardType: EteeloTextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\- ]')),
                ],
                onSubmitted: (_) => _search(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Align(
          alignment: Alignment.centerRight,
          child: EteeloButton.primary(
            label: l10n.search,
            onPressed: _canSearch ? _search : null,
          ),
        ),
      ],
    );
  }

  Widget _buildResults(AppLocalizations l10n) {
    return BlocBuilder<ParentSearchBloc, ParentSearchState>(
      builder: (context, state) {
        return switch (state) {
          ParentSearchInitial() => SizedBox(
            height: AppDimensions.guardianSearchResultsMinHeight,
            child: Center(
              child: Text(
                l10n.guardianSearchHint,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          ParentSearchLoading() => EteeloListSkeleton(
            rowCount: 3,
            pillCount: 0,
            semanticsLabel: l10n.guardianSearchDialogTitle,
          ),
          ParentSearchLoaded(:final results) => _ResultsList(
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
              onPressed: _search,
            ),
          ),
        };
      },
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<LocalParent> results;
  final ValueChanged<LocalParent> onSelected;

  const _ResultsList({required this.results, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: results.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: AppDimensions.spacingS),
      itemBuilder: (context, index) {
        final parent = results[index];
        final fullName = [
          parent.firstName,
          parent.surname,
          parent.lastName,
        ].where((part) => part != null && part.trim().isNotEmpty).join(' ');

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelected(parent),
            borderRadius: AppRadius.brMd,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.brMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          parent.phoneNumber,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
