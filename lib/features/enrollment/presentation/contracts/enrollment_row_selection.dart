import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';

/// Le mode sélection d'une liste d'inscriptions : les lignes cochées et le
/// geste qui coche. Posé par l'écran au-dessus des résultats ; la table et la
/// grille le lisent sans qu'on le leur passe.
class EnrollmentRowSelection {
  final Set<String> selected;
  final ValueChanged<EnrollmentSummary> onToggle;

  const EnrollmentRowSelection({
    required this.selected,
    required this.onToggle,
  });

  /// Seul un dossier complété et pas déjà désactivé se coche.
  static bool isEligible(EnrollmentSummary s) =>
      s.isSuspendable && !s.isSuspended;

  bool isSelected(EnrollmentSummary s) => selected.contains(s.enrollmentId);
}

/// Porte la [EnrollmentRowSelection] courante ; `null` hors mode sélection.
class EnrollmentRowSelectionScope extends InheritedWidget {
  final EnrollmentRowSelection? selection;

  const EnrollmentRowSelectionScope({
    super.key,
    required this.selection,
    required super.child,
  });

  static EnrollmentRowSelection? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<EnrollmentRowSelectionScope>()
      ?.selection;

  @override
  bool updateShouldNotify(EnrollmentRowSelectionScope oldWidget) =>
      oldWidget.selection?.selected != selection?.selected ||
      (oldWidget.selection == null) != (selection == null);
}
