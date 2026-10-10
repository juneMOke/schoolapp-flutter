import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/common/journal_break_band.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/sheet/journal_sheet_header.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/sheet/journal_sheet_row.dart';

/// La feuille du jour, fidèle au cahier : neuf colonnes, une ligne par
/// séance, la récréation en bande. Défile horizontalement sous sa largeur
/// minimale.
class JournalSheet extends StatelessWidget {
  final List<JournalLine> lines;
  final ValueChanged<JournalLine>? onOpen;

  const JournalSheet({super.key, required this.lines, this.onOpen});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sheet = DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.brLg,
            border: Border.all(color: AppColors.journalLine),
          ),
          child: ClipRRect(
            borderRadius: AppRadius.brLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const JournalSheetHeader(),
                for (final line in lines) ...[
                  if (line.breakBefore case final pause?)
                    JournalBreakBand(pause: pause),
                  JournalSheetRow(
                    line: line,
                    onTap: onOpen == null ? null : () => onOpen!(line),
                  ),
                ],
              ],
            ),
          ),
        );
        if (constraints.maxWidth >= AppDimensions.journalSheetMinWidth) {
          return sheet;
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: AppDimensions.journalSheetMinWidth,
            child: sheet,
          ),
        );
      },
    );
  }
}
