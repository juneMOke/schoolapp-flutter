import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_row_selection.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_reason.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspension_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce qu'une ligne ou une carte de résultat montre d'un élève désactivé, et
/// la case du mode sélection — partagés par la table et la grille.
abstract final class EnrollmentSuspensionMarks {
  /// Opacité de l'identité d'un élève désactivé : « Désactivé » reste écrit,
  /// l'opacité ne fait que l'accompagner.
  static const double suspendedOpacity = 0.55;

  /// La pastille « Désactivé », son motif et sa date en infobulle.
  static Widget badge(
    EnrollmentSummary s,
    AppLocalizations l10n, {
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) {
    final reason = SuspensionReason.fromWire(s.suspensionReason)?.label(l10n);
    final since = l10n.suspensionSince(s.suspendedAt!);
    return Tooltip(
      message: reason == null ? since : '$reason · $since',
      child: StatusBadge.suspended(label: l10n.suspensionBadge, size: size),
    );
  }

  /// Une carte d'élève désactivé, désaturée à 60 %.
  static Widget dimmed(Widget child) =>
      ColorFiltered(colorFilter: _desaturate, child: child);

  // Saturation 0,4 (luminances Rec. 709) : la carte garde un reste de teinte.
  static const ColorFilter _desaturate = ColorFilter.matrix(<double>[
    0.4 + 0.6 * 0.2126, 0.6 * 0.7152, 0.6 * 0.0722, 0, 0, //
    0.6 * 0.2126, 0.4 + 0.6 * 0.7152, 0.6 * 0.0722, 0, 0, //
    0.6 * 0.2126, 0.6 * 0.7152, 0.4 + 0.6 * 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  /// La case d'une ligne en mode sélection : grisée et hors du focus pour un
  /// dossier qui ne se désactive pas.
  static Widget checkbox(
    EnrollmentSummary s,
    EnrollmentRowSelection selection,
    AppLocalizations l10n,
  ) {
    final eligible = EnrollmentRowSelection.isEligible(s);
    return Semantics(
      label: l10n.suspensionSelectStudent(
        '${s.student.lastName} ${s.student.firstName}',
      ),
      child: Opacity(
        opacity: eligible ? 1 : 0.5,
        child: Checkbox(
          value: eligible && selection.isSelected(s),
          onChanged: eligible ? (_) => selection.onToggle(s) : null,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
