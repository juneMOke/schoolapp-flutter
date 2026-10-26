import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_month_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un mois de la frise et son statut (`null` : pas de paie).
typedef PayrollMonthEntry = ({String month, PayrollPhase? phase});

/// La frise des mois de paie : une pastille par mois, du plus ancien à gauche
/// au plus récent à droite, chacune au voile de son statut. Elle défile de
/// côté et garde le mois affiché à l'écran.
///
/// Les statuts viennent de l'appelant : la tablette pour le livre, le serveur
/// (`months`) pour le tableau de bord.
class PayrollMonthStrip extends StatefulWidget {
  /// Du plus ancien au plus récent.
  final List<PayrollMonthEntry> months;
  final String selected;
  final ValueChanged<String> onSelect;

  const PayrollMonthStrip({
    super.key,
    required this.months,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<PayrollMonthStrip> createState() => _PayrollMonthStripState();
}

class _PayrollMonthStripState extends State<PayrollMonthStrip> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(jump: true));
  }

  @override
  void didUpdateWidget(covariant PayrollMonthStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double _extent(BuildContext context) =>
      MediaQuery.textScalerOf(
        context,
      ).scale(AppDimensions.payrollMonthPillWidth) +
      AppSpacing.xs;

  /// Centre le mois affiché. La frise est posée à l'envers (le plus récent à
  /// droite, visible d'abord) : l'index 0 est le dernier mois.
  void _reveal({bool jump = false}) {
    if (!mounted || !_scroll.hasClients) return;
    final months = widget.months;
    if (months.isEmpty) return;
    final index = PayrollMonth.between(widget.selected, months.last.month);
    if (index < 0 || index >= months.length) return;
    final extent = _extent(context);
    final position = _scroll.position;
    final target = (index * extent - (position.viewportDimension - extent) / 2)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (jump || (MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: AppMotion.standard,
        curve: AppMotion.outCurve,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final months = widget.months;
    final extent = _extent(context);
    return Semantics(
      container: true,
      label: AppLocalizations.of(context)!.payrollMonthStripA11y,
      child: SizedBox(
        height: MediaQuery.textScalerOf(
          context,
        ).scale(AppDimensions.minTouchTarget + AppSpacing.md),
        child: Scrollbar(
          controller: _scroll,
          child: ListView.builder(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            reverse: true,
            itemExtent: extent,
            itemCount: months.length,
            itemBuilder: (context, index) {
              final entry = months[months.length - 1 - index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: PayrollMonthPill(
                    month: entry.month,
                    phase: entry.phase,
                    selected: entry.month == widget.selected,
                    onTap: () => widget.onSelect(entry.month),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
