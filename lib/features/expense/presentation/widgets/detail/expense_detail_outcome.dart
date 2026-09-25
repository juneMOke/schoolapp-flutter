import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';

/// Ce que la fiche demande à l'écran de faire **après** sa fermeture.
///
/// Deux familles, et la distinction n'est pas cosmétique : un raccourci
/// rouvre une modale de saisie, un geste écrit dans le circuit. Les fondre
/// dans une seule énumération obligerait à transporter un motif de refus qui
/// n'a de sens que pour l'un des deux.
sealed class ExpenseDetailOutcome {
  const ExpenseDetailOutcome();
}

/// Les gestes d'écran de la V1 : ils ne touchent pas au circuit.
enum ExpenseDetailChoice { withdraw, duplicate, edit }

final class ExpenseDetailShortcut extends ExpenseDetailOutcome {
  final ExpenseDetailChoice choice;

  const ExpenseDetailShortcut(this.choice);
}

/// Un geste du circuit, avec son mot.
///
/// [note] porte le motif d'un refus — **obligatoire**, et la fiche ne rend
/// jamais ce résultat sans lui. Partout ailleurs elle est vide : le geste se
/// suffit, et son libellé s'écrira au fil.
final class ExpenseDetailGesture extends ExpenseDetailOutcome {
  final ExpenseGesture gesture;
  final String note;

  const ExpenseDetailGesture(this.gesture, {this.note = ''});
}
