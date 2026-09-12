import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_designation.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_fee_options.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_page_helpers.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// **Rejouer la requête en clair.**
///
/// L'écran redit ce qu'on lui a demandé — les frais, la classe, la situation,
/// le plancher — au-dessus du résultat comme dans l'état vide. C'est ce qui
/// permet de voir *ce qui est trop étroit* sans remonter au formulaire.
///
/// Les frais se nomment **exactement comme les pastilles les nomment** — par
/// le titre que l'école donne à la nature, sinon par la grille : une phrase qui
/// rappelle « Minerval » là où l'opérateur a coché « Frais scolaires annuels »
/// lui fait douter de ce qu'il a demandé.
class FeeControlQueryPhrase {
  const FeeControlQueryPhrase._();

  /// Les morceaux de la requête, dans l'ordre où ils l'expliquent : les frais
  /// et la situation d'abord — ce sont eux qui expliquent une liste vide.
  static List<String> parts(
    FeeControlState state,
    AppLocalizations l10n, {
    FeeSectionTitlesState titles = const FeeSectionTitlesState(),
  }) {
    final query = state.lastQuery;
    if (query == null) return const <String>[];

    final parts = <String>[];
    final fees = _feeLabels(state, l10n, titles: titles);
    if (fees.isNotEmpty) parts.add(fees.join(' + '));

    // Nom de la classe plutôt que son id — l'id ne dit rien à personne. Le
    // repli « toutes les classes » n'est pas affiché : c'est le défaut.
    final classroomId = query.classroomId;
    if (classroomId != null) {
      final name = state.classrooms
          .where((c) => c.id == classroomId)
          .map((c) => c.name)
          .firstOrNull;
      if (name != null) parts.add(name);
    }

    if (query.statusFilter != FeeControlPaymentFilter.all) {
      parts.add(
        FeeControlPageHelpers.paymentFilterLabel(query.statusFilter, l10n),
      );
    }
    // Le plancher fait partie de la question : sans lui, « a payé au moins… »
    // ne dit pas au moins quoi.
    final threshold = query.threshold;
    if (threshold != null) parts.add(MoneyFormat.format(threshold));
    return parts;
  }

  /// Le sous-titre de la section de résultat : la requête, puis l'ordre — parce
  /// que cet ordre-là n'est pas alphabétique et surprendrait sans un mot.
  static String subtitle(
    FeeControlState state,
    AppLocalizations l10n, {
    FeeSectionTitlesState titles = const FeeSectionTitlesState(),
  }) => [
    ...parts(state, l10n, titles: titles),
    l10n.feeControlResultOrder,
  ].join(' · ');

  /// Les mêmes morceaux, mais étiquetés — la forme que l'état vide affiche en
  /// puces.
  static List<String> chips(
    FeeControlState state,
    AppLocalizations l10n, {
    FeeSectionTitlesState titles = const FeeSectionTitlesState(),
  }) {
    final query = state.lastQuery;
    if (query == null) return const <String>[];

    final chips = <String>[];
    // La puce d'un état vide **désigne** le frais en entier — libellé de la
    // grille et code — là où le sous-titre se contente du nom court : c'est
    // elle qui doit permettre de vérifier qu'on a bien cherché ce qu'on
    // croyait chercher.
    final fees = _feeLabels(state, l10n, full: true, titles: titles);
    if (fees.isNotEmpty) {
      chips.add(l10n.feeControlCriteriaFee(fees.join(' + ')));
    }

    final classroomId = query.classroomId;
    if (classroomId != null) {
      final name = state.classrooms
          .where((c) => c.id == classroomId)
          .map((c) => c.name)
          .firstOrNull;
      if (name != null) chips.add(l10n.feeControlCriteriaClassroom(name));
    }

    if (query.statusFilter != FeeControlPaymentFilter.all) {
      chips.add(
        l10n.feeControlCriteriaStatus(
          FeeControlPageHelpers.paymentFilterLabel(query.statusFilter, l10n),
        ),
      );
    }
    final threshold = query.threshold;
    if (threshold != null) {
      chips.add(
        l10n.feeControlCriteriaThreshold(MoneyFormat.format(threshold)),
      );
    }
    return chips;
  }

  /// Chaque frais retenu, nommé comme sa pastille.
  ///
  /// L'ordre est celui de la **requête**, pas celui de la grille courante : la
  /// phrase doit décrire ce qui a été cherché, même si l'opérateur a changé de
  /// niveau depuis.
  static List<String> _feeLabels(
    FeeControlState state,
    AppLocalizations l10n, {
    bool full = false,
    required FeeSectionTitlesState titles,
  }) {
    final query = state.lastQuery;
    if (query == null) return const <String>[];
    final options = {
      for (final option in buildFeeControlFeeOptions(state.tariffs))
        option.feeCode: option,
    };
    return [
      for (final code in query.feeCodes)
        if (full)
          feeDesignation(
            // Une ligne de grille unique se désigne par elle-même — libellé et
            // code : c'est ce qui permet de vérifier qu'on a cherché la bonne.
            // Plusieurs tranches n'ont pas de libellé commun : le titre de la
            // section les nomme, plutôt que la nature générique.
            label: options[code]?.isSingleTariff ?? false
                ? options[code]!.tariffLabel
                : (titles.titleOf(code) ?? ''),
            feeCode: code,
            feeTariffCode: options[code]?.tariffCode,
            l10n: l10n,
          )
        else
          feeControlFeeCodeLabel(
            options[code],
            code,
            l10n,
            sectionTitle: titles.titleOf(code),
          ),
    ];
  }
}
