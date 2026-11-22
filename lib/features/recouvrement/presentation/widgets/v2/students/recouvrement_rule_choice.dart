import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recouvrement_rule_option.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_texts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// 🆕 La règle « est en ordre l'élève qui… » (R8, spec §4.6 E) : trois choix
/// exclusifs **tous visibles**, chacun avec son effet chiffré avant d'être
/// touché (A8), le montant d'« a payé au moins » saisi dans le choix, et ce
/// choix grisé avec sa raison quand francs et dollars sont cochés ensemble.
///
/// Trois colonnes dès 600 reçus, empilées en deçà ; rôle radio, flèches au
/// clavier.
class RecouvrementRuleChoice extends StatefulWidget {
  final RecoveryRuleKind rule;

  /// Le montant d'« a payé au moins », en centimes de la devise du
  /// périmètre ; `null` tant que rien n'est saisi.
  final int? thresholdInCents;
  final RecoveryRuleCounts counts;

  /// L'effectif : la jauge vaut compteur / effectif.
  final int studentCount;
  final bool atLeastAvailable;

  /// L'unique devise du périmètre ; `null` en mixte.
  final String? currency;
  final ValueChanged<RecoveryRuleKind> onRuleChanged;

  /// Appelé à chaque chiffre, en centimes ; `null` quand le champ se vide.
  final ValueChanged<int?> onThresholdChanged;

  /// Empilé ? Par défaut, sous 600 dp reçus par le choix lui-même ; le
  /// panneau le pose d'après la largeur que **lui** reçoit (§4.1).
  final bool? narrow;

  const RecouvrementRuleChoice({
    super.key,
    required this.rule,
    required this.thresholdInCents,
    required this.counts,
    required this.studentCount,
    required this.atLeastAvailable,
    required this.currency,
    required this.onRuleChanged,
    required this.onThresholdChanged,
    this.narrow,
  });

  @override
  State<RecouvrementRuleChoice> createState() => _RecouvrementRuleChoiceState();
}

class _RecouvrementRuleChoiceState extends State<RecouvrementRuleChoice> {
  final _nodes = {
    for (final r in RecoveryRuleKind.values)
      r: FocusNode(debugLabel: 'rule-${r.wire}'),
  };

  @override
  void dispose() {
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  bool _enabled(RecoveryRuleKind r) =>
      r != RecoveryRuleKind.atLeast || widget.atLeastAvailable;

  /// Le choix effectivement coché : « au moins » indisponible revient à la
  /// règle par défaut (R8).
  RecoveryRuleKind get _checked =>
      _enabled(widget.rule) ? widget.rule : RecoveryRuleKind.somePayment;

  /// Flèches : le choix suivant (ou précédent) activable devient le choix
  /// coché, comme un groupe radio natif.
  KeyEventResult _onKey(RecoveryRuleKind from, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    // Le champ de montant vit dans le troisième choix : ses flèches restent
    // les siennes.
    if (!_nodes[from]!.hasPrimaryFocus) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      if (from != _checked) widget.onRuleChanged(from);
      return KeyEventResult.handled;
    }
    final step =
        key == LogicalKeyboardKey.arrowRight ||
            key == LogicalKeyboardKey.arrowDown
        ? 1
        : key == LogicalKeyboardKey.arrowLeft ||
              key == LogicalKeyboardKey.arrowUp
        ? -1
        : 0;
    if (step == 0) return KeyEventResult.ignored;
    const all = RecoveryRuleKind.values;
    var i = all.indexOf(from);
    for (var k = 0; k < all.length; k++) {
      i = (i + step) % all.length;
      if (_enabled(all[i])) break;
    }
    final next = all[i];
    _nodes[next]!.requestFocus();
    if (next != _checked) widget.onRuleChanged(next);
    return KeyEventResult.handled;
  }

  int? _countOf(RecoveryRuleKind r) => switch (r) {
    RecoveryRuleKind.somePayment => widget.counts.somePayment,
    RecoveryRuleKind.fullySettled => widget.counts.fullySettled,
    RecoveryRuleKind.atLeast =>
      widget.thresholdInCents == null ? null : widget.counts.atLeast,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow =
            widget.narrow ??
            constraints.maxWidth < AppBreakpoints.dataTableCardsMax;
        final options = [
          for (final r in RecoveryRuleKind.values)
            RecouvrementRuleOption(
              rule: r,
              label: switch (r) {
                RecoveryRuleKind.somePayment =>
                  l10n.recoveryStudentsRuleSomePayment,
                RecoveryRuleKind.fullySettled =>
                  l10n.recoveryStudentsRuleFullySettled,
                RecoveryRuleKind.atLeast => l10n.recoveryStudentsRuleAtLeast,
              },
              checked: r == _checked,
              enabled: _enabled(r),
              narrow: narrow,
              count: _countOf(r),
              awaitingAmount:
                  r == RecoveryRuleKind.atLeast &&
                  widget.thresholdInCents == null,
              studentCount: widget.studentCount,
              focusNode: _nodes[r]!,
              onKey: (event) => _onKey(r, event),
              onSelected: () {
                if (r != _checked) widget.onRuleChanged(r);
              },
              thresholdInCents: widget.thresholdInCents,
              currency: widget.currency,
              onThresholdChanged: widget.onThresholdChanged,
            ),
        ];
        return Semantics(
          container: true,
          explicitChildNodes: true,
          label: l10n.recoveryStudentsRuleHeading,
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.sm,
                  children: options,
                )
              : DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.brLg,
                    color: DashboardTones.teinte(
                      AppColors.bleuProfond,
                      RecoveryStudentsTones.softPercent,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [for (final o in options) Expanded(child: o)],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
