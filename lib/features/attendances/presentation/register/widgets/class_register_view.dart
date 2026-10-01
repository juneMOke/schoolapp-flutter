import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_card.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_list_frame.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_row.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_day_register.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/helpers/class_presence_view.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/widgets/class_row_actions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le registre de la classe, en cartes ou en liste — les widgets communs,
/// sans départ ni heures prestées (le Pointage seul les porte).
class ClassRegisterView extends StatelessWidget {
  final ClassDayRegister register;
  final CollectionViewMode viewMode;
  final String classroomName;

  /// « Justifier » est proposé (cf. `classDayLock`, `justifying`).
  final bool canJustify;

  const ClassRegisterView({
    super.key,
    required this.register,
    required this.viewMode,
    required this.classroomName,
    this.canJustify = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = register.rows;
    final schedule = register.day.schedule;
    final body = viewMode == CollectionViewMode.grid
        ? EteeloGridView(
            padding: EdgeInsets.zero,
            minItemWidth: AppDimensions.presenceMarkCardMinWidth,
            itemCount: rows.length,
            itemBuilder: (context, index) => PresenceCard(
              key: ValueKey(rows[index].student.id),
              row: rows[index].presenceView(
                l10n,
                classroomName,
                canJustify: canJustify,
              ),
              actions: ClassRowActions(context, rows[index]),
              schedule: schedule,
            ),
          )
        : PresenceListFrame(
            personColumn: l10n.classPresenceColStudent,
            rows: [
              for (final line in rows)
                PresenceRow(
                  key: ValueKey(line.student.id),
                  row: line.presenceView(
                    l10n,
                    classroomName,
                    canJustify: canJustify,
                  ),
                  actions: ClassRowActions(context, line),
                ),
            ],
          );
    return Opacity(
      opacity: register.frozen ? AppDimensions.presenceMarkFrozenOpacity : 1,
      child: body,
    );
  }
}
