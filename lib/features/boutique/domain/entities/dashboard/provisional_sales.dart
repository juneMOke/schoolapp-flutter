import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/provisional_sale_line.dart';

/// Les tickets provisoires d'une fenêtre : ce que ce poste a encaissé et que le
/// serveur ne compte pas encore.
class ProvisionalSales extends Equatable {
  static const ProvisionalSales none = ProvisionalSales([]);

  final List<ProvisionalSaleLine> lines;

  const ProvisionalSales(this.lines);

  bool get isEmpty => lines.isEmpty;

  /// Le nombre de **ventes** — de tickets —, pas de lignes.
  int get saleCount => {for (final line in lines) line.saleId}.length;

  int get articleCount => lines.fold(0, (total, line) => total + line.quantity);

  /// Ce qu'ils pèsent, par devise.
  MoneyBag get amounts => MoneyBag.sumBy(
    lines,
    (line) => Money.parse(line.lineTotal, line.currency),
  );

  @override
  List<Object?> get props => [lines];
}
