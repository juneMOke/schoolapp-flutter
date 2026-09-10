import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_fee_code_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_designation.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que le sélecteur « Frais » du Contrôle propose vraiment : **une entrée par
/// nature**, nommée par la grille de l'école quand celle-ci le permet.
///
/// La maille n'est pas un choix d'affichage, elle est imposée par la mesure :
/// `getFeeChargeAggregates` joint les créances par `fee_code` avec des `SUM`, et
/// le contrôle répond donc « où en est cet élève sur CE FRAIS », tranches
/// confondues. Offrir une entrée par ligne de grille ferait sept choix qui
/// donnent tous le même tableau.
///
/// Reste que « Minerval » n'est pas ce que l'école a écrit. Quand la nature ne
/// porte **qu'une** ligne, cette ligne EST la nature : son libellé et son code
/// nomment l'entrée, comme partout ailleurs en Finance. Quand elle en porte
/// plusieurs, aucun des libellés ne vaut pour l'ensemble — l'entrée retombe sur
/// la nature et **annonce le nombre de tranches**, plutôt que d'emprunter le nom
/// de la première et de laisser croire qu'on ne contrôle qu'elle.
class FeeControlFeeOption {
  final String feeCode;

  /// Libellé de la ligne de grille, ou `''` quand la nature en porte plusieurs.
  /// Vide, il fait retomber la désignation sur la nature localisée — c'est le
  /// repli que `feeDesignation` sait déjà tenir.
  final String tariffLabel;

  /// Code de la ligne de grille, `null` dès qu'il ne désigne plus une ligne
  /// unique. La règle « ce code distingue-t-il quelque chose ? » reste, elle,
  /// tranchée à l'affichage par `meaningfulTariffCode`.
  final String? tariffCode;

  /// Nombre de lignes de grille regroupées sous cette nature — toujours ≥ 1.
  final int tariffCount;

  /// Attendu total de la nature, en centimes, ou `null` si les lignes ne
  /// partagent pas la même devise : additionner deux devises ne produirait
  /// aucun montant vrai.
  final int? amountInCents;

  /// Devise de [amountInCents], `null` en même temps que lui.
  final String? currency;

  const FeeControlFeeOption({
    required this.feeCode,
    required this.tariffLabel,
    required this.tariffCode,
    required this.tariffCount,
    required this.amountInCents,
    required this.currency,
  });

  /// Vrai quand la nature ne porte qu'une ligne de grille — le seul cas où le
  /// libellé et le code de l'école décrivent exactement ce qui sera contrôlé.
  bool get isSingleTariff => tariffCount == 1;
}

/// Regroupe la grille d'un niveau par nature, dans l'ordre de première
/// apparition (celui du DAO, `fee_code ASC`).
///
/// Le regroupement ne sert pas qu'à l'esthétique du menu : sans lui, une grille
/// portant à la fois un tarif de cycle et un tarif de niveau du même code
/// produirait deux entrées de même valeur, et le sélecteur casserait.
List<FeeControlFeeOption> buildFeeControlFeeOptions(
  List<LocalFeeTariff> tariffs,
) {
  final grouped = <String, List<LocalFeeTariff>>{};
  for (final tariff in tariffs) {
    (grouped[tariff.feeCode] ??= <LocalFeeTariff>[]).add(tariff);
  }

  return grouped.entries
      .map((entry) => _optionFor(entry.key, entry.value))
      .toList(growable: false);
}

/// L'option d'une nature donnée, à partir des lignes de grille qui la portent.
FeeControlFeeOption? feeControlFeeOptionFor(
  List<LocalFeeTariff> tariffs,
  String? feeCode,
) {
  if (feeCode == null) return null;
  final matching = tariffs
      .where((tariff) => tariff.feeCode == feeCode)
      .toList(growable: false);
  return matching.isEmpty ? null : _optionFor(feeCode, matching);
}

FeeControlFeeOption _optionFor(String feeCode, List<LocalFeeTariff> tariffs) {
  final single = tariffs.length == 1 ? tariffs.first : null;
  final currency = tariffs.first.currency;
  final sameCurrency = tariffs.every((tariff) => tariff.currency == currency);
  var total = 0;
  for (final tariff in tariffs) {
    total += tariff.amountInCents;
  }

  return FeeControlFeeOption(
    feeCode: feeCode,
    tariffLabel: single?.label ?? '',
    tariffCode: single?.code,
    tariffCount: tariffs.length,
    amountInCents: sameCurrency ? total : null,
    currency: sameCurrency ? currency : null,
  );
}

/// Comment une entrée du sélecteur se **nomme**.
///
/// Une seule ligne de grille → la même désignation que partout ailleurs en
/// Finance (`feeDesignation` : « Organisation matériel — 2/3 (OM2) »), suivie du
/// montant, qui lève l'ambiguïté entre deux frais de noms proches sans obliger à
/// ouvrir la grille.
///
/// Plusieurs → la nature localisée, le nombre de tranches, puis leur total. Le
/// total est bien ce que le contrôle mesurera : les `SUM` de l'agrégat les
/// additionnent aussi. Il s'efface si les tranches ne partagent pas la devise —
/// un montant faux vaut moins que pas de montant.
String feeControlFeeOptionLabel(
  FeeControlFeeOption option,
  AppLocalizations l10n,
) {
  final amountInCents = option.amountInCents;
  final currency = option.currency;

  return [
    if (option.isSingleTariff)
      feeDesignation(
        label: option.tariffLabel,
        feeCode: option.feeCode,
        feeTariffCode: option.tariffCode,
        l10n: l10n,
      )
    else ...[
      option.feeCode.localizedFeeLabel(l10n),
      l10n.feeControlFeeTrancheCount(option.tariffCount),
    ],
    if (amountInCents != null && currency != null)
      MoneyFormat.format(Money.parse(amountInCents, currency)),
  ].join(' · ');
}
