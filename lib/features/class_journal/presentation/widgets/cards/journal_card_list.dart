import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/cards/journal_session_card.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/common/journal_break_band.dart';

/// Les séances du jour en cartes, sous le point de rupture : une carte par
/// séance, la récréation en bande entre deux cartes.
class JournalCardList extends StatelessWidget {
  final List<JournalLine> lines;
  final ValueChanged<JournalLine>? onOpen;

  const JournalCardList({super.key, required this.lines, this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          if (lines[i].breakBefore case final pause?) ...[
            ClipRRect(
              borderRadius: AppRadius.brSm,
              child: JournalBreakBand(pause: pause),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          JournalSessionCard(
            line: lines[i],
            onTap: onOpen == null ? null : () => onOpen!(lines[i]),
          ),
        ],
      ],
    );
  }
}
