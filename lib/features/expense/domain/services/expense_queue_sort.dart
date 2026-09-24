import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';

/// Les trois lectures de la file (spec §05).
///
/// L'**ancienneté** est le défaut, et ce n'est pas un hasard : la file existe
/// pour que le retard se voie en premier. Les deux autres servent des gestes
/// précis — dégager les gros montants, ou traiter d'un bloc les demandes d'un
/// même agent.
enum ExpenseQueueSort { age, amount, requester }

/// Le tri de la file, isolé pour être testable seul.
///
/// Chaque comparateur **retombe sur l'ancienneté** puis sur l'identifiant : un
/// tri instable ferait danser les lignes d'une relecture à l'autre, et la file
/// se relit à chaque battement de synchro.
abstract final class ExpenseQueueOrder {
  static List<Expense> apply(
    List<Expense> pending,
    ExpenseQueueSort sort,
    ExpenseUsdReader reader,
  ) {
    final rows = [...pending];
    rows.sort(switch (sort) {
      ExpenseQueueSort.age => _byAge,
      ExpenseQueueSort.amount => (a, b) => _byAmount(a, b, reader),
      ExpenseQueueSort.requester => _byRequester,
    });
    return rows;
  }

  /// Du plus ancien au plus récent — la tête de file est ce qui attend depuis
  /// le plus longtemps.
  static int _byAge(Expense a, Expense b) {
    final byDay = a.dayKey.compareTo(b.dayKey);
    return byDay != 0 ? byDay : a.id.compareTo(b.id);
  }

  /// Du plus gros au plus petit, **en lecture dollars**.
  ///
  /// Sans taux publié, un montant en francs ne se lit pas : il passe en fin de
  /// file plutôt que d'être comparé à un dollar comme s'il en valait un (A5).
  /// Les incomparables restent entre eux dans l'ordre d'ancienneté.
  static int _byAmount(Expense a, Expense b, ExpenseUsdReader reader) {
    final left = reader.usdCentsOf(a.money);
    final right = reader.usdCentsOf(b.money);
    if (left == null || right == null) {
      if (left != right) return left == null ? 1 : -1;
      return _byAge(a, b);
    }
    final byAmount = right.compareTo(left);
    return byAmount != 0 ? byAmount : _byAge(a, b);
  }

  /// Par demandeur, **casse et accents ignorés** (A12) : « Élodie » se range
  /// avec « Elodie », pas après « Zacharie ». Un nom absent ferme la marche.
  static int _byRequester(Expense a, Expense b) {
    final left = SearchNormalizationHelper.normalize(a.recordedByName ?? '');
    final right = SearchNormalizationHelper.normalize(b.recordedByName ?? '');
    if (left.isEmpty || right.isEmpty) {
      if (left.isEmpty != right.isEmpty) return left.isEmpty ? 1 : -1;
      return _byAge(a, b);
    }
    final byName = left.compareTo(right);
    return byName != 0 ? byName : _byAge(a, b);
  }
}
