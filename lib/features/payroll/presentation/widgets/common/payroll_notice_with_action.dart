import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/layout/leading_trailing_row.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Un bandeau du livre et son geste : à droite sur une largeur de tablette,
/// dessous sur une largeur de téléphone — comme `PayrollCallout`.
///
/// Côte à côte dans une `Row`, le bouton gardait sa largeur naturelle et la
/// note, en `Expanded`, prenait le reste : à 360 dp en texte ×1,3, plus rien,
/// et la rangée débordait.
class PayrollNoticeWithAction extends StatelessWidget {
  final Widget notice;

  /// `null` : le bandeau se lit seulement.
  final Widget? action;

  const PayrollNoticeWithAction({
    super.key,
    required this.notice,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    if (action == null) return notice;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppBreakpoints.dataTableCardsMax) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              notice,
              const SizedBox(height: AppSpacing.xs),
              Align(alignment: AlignmentDirectional.centerEnd, child: action),
            ],
          );
        }
        return LeadingTrailingRow(
          leading: notice,
          trailing: action,
          gap: AppSpacing.sm,
        );
      },
    );
  }
}
