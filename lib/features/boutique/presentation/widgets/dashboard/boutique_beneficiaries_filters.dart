import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/eteelo_search_toolbar.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_beneficiaries_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Nom · article · classe — trois filtres **cumulatifs**.
class BoutiqueBeneficiariesFilters extends StatelessWidget {
  final BoutiqueBeneficiariesState state;
  final BoutiqueBeneficiariesCubit cubit;

  /// « Tous » se lit comme une valeur vide : le menu ne porte pas de `null`.
  static const String _all = '';
  static const double _selectWidth = 220;

  const BoutiqueBeneficiariesFilters({
    super.key,
    required this.state,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String? orNull(String? value) =>
        value == null || value == _all ? null : value;

    return EteeloSearchToolbar(
      text: state.search,
      label: l10n.boutiqueBeneficiariesSearchLabel,
      placeholder: l10n.boutiqueBeneficiariesSearchHint,
      onTextChanged: cubit.searchChanged,
      filters: [
        SizedBox(
          width: _selectWidth,
          child: EteeloSelectInput<String>(
            label: l10n.boutiqueBeneficiariesArticleLabel,
            value: state.articleId ?? _all,
            onChanged: (value) => cubit.articleSelected(orNull(value)),
            items: [
              EteeloSelectItem(
                value: _all,
                label: l10n.boutiqueBeneficiariesAllArticles,
              ),
              for (final option in state.articleOptions)
                EteeloSelectItem(value: option.id, label: option.label),
            ],
          ),
        ),
        SizedBox(
          width: _selectWidth,
          child: EteeloSelectInput<String>(
            label: l10n.boutiqueBeneficiariesClassLabel,
            value: state.classId ?? _all,
            onChanged: (value) => cubit.classSelected(orNull(value)),
            items: [
              EteeloSelectItem(
                value: _all,
                label: l10n.boutiqueBeneficiariesAllClasses,
              ),
              for (final c in state.page?.classes ?? const [])
                EteeloSelectItem(value: c.id, label: c.label),
              // La classe choisie reste au menu, même si cette période ne la
              // porte plus : le filtre actif doit se voir.
              if (state.classId != null &&
                  !(state.page?.classes ?? const []).any(
                    (c) => c.id == state.classId,
                  ))
                EteeloSelectItem(
                  value: state.classId!,
                  label: state.classLabel ?? state.classId!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
