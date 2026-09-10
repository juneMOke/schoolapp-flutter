part of 'finance_till_bloc.dart';

const Object _undefined = Object();

enum FinanceTillStatus { initial, loading, success, error }

class FinanceTillState extends Equatable {
  final FinanceTillStatus status;
  final FinanceTill? till;

  /// L'échec lui-même — voir [FinanceRecoveryState.failure].
  final Failure? failure;

  /// La fenêtre affichée. [TillPeriod.day] au premier montage.
  ///
  /// ⚠️ Aucune **ancre** ici, et c'est délibéré : les quatre grains portent
  /// toujours la fenêtre courante. Le jour où l'écran proposera de viser une
  /// journée passée, l'ancre devra être **remise à zéro à chaque changement de
  /// grain** — le serveur refuse en 400 une ancre qui ne correspond pas à la
  /// période, et un état qui garderait l'ancienne produirait un écran d'erreur
  /// sur un simple clic d'onglet.
  final TillWindow selectedWindow;

  /// La caisse détaillée sous les tuiles — le code de sa devise.
  ///
  /// **Conservée d'une fenêtre à l'autre** : changer de période ne doit pas
  /// ramener le lecteur sur une autre caisse que celle qu'il examinait. Elle
  /// n'est réarbitrée que si la nouvelle réponse ne porte plus cette devise.
  ///
  /// `null` tant qu'aucune réponse n'est arrivée, ou quand la réponse ne porte
  /// aucun bloc : il n'y a alors pas de caisse à détailler, et c'est l'état vide
  /// global qui parle.
  final String? selectedCurrency;

  const FinanceTillState({
    this.status = FinanceTillStatus.initial,
    this.till,
    this.failure,
    this.selectedWindow = const TillWindow.day(),
    this.selectedCurrency,
  });

  /// Le bloc détaillé, ou `null` si la sélection ne désigne rien.
  ///
  /// Résolu ici plutôt que dans chaque widget : plusieurs sections descendent de
  /// cette même caisse, et les laisser la retrouver chacune de son côté est le
  /// chemin le plus court vers deux sections qui n'affichent pas la même.
  TillCurrencyBlock? get selectedBlock {
    final blocks = till?.encaisse;
    if (blocks == null || selectedCurrency == null) return null;
    for (final block in blocks) {
      if (block.currency == selectedCurrency) return block;
    }
    return null;
  }

  FinanceTillState copyWith({
    FinanceTillStatus? status,
    Object? till = _undefined,
    Object? failure = _undefined,
    TillWindow? selectedWindow,
    Object? selectedCurrency = _undefined,
  }) => FinanceTillState(
    status: status ?? this.status,
    till: identical(till, _undefined) ? this.till : till as FinanceTill?,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
    selectedWindow: selectedWindow ?? this.selectedWindow,
    selectedCurrency: identical(selectedCurrency, _undefined)
        ? this.selectedCurrency
        : selectedCurrency as String?,
  );

  @override
  List<Object?> get props => [
    status,
    till,
    failure,
    selectedWindow,
    selectedCurrency,
  ];
}
