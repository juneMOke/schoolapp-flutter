import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/states/programme_failure_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Chargement d'une page : trois séances fantômes.
class JournalSkeleton extends StatelessWidget {
  const JournalSkeleton({super.key});

  @override
  Widget build(BuildContext context) => EteeloListSkeleton(
    rowCount: 3,
    pillCount: 1,
    semanticsLabel: AppLocalizations.of(context)!.journalLoading,
  );
}

/// Aucun cours ce jour : la date dans le message, et l'accès au prochain jour
/// de cours quand il y en a un.
class JournalEmptyDay extends StatelessWidget {
  final DateTime date;
  final DateTime? nextCourseDay;
  final ValueChanged<DateTime> onOpenDay;

  const JournalEmptyDay({
    super.key,
    required this.date,
    required this.onOpenDay,
    this.nextCourseDay,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final next = nextCourseDay;
    return EteeloEmptyResult(
      label: l10n.journalEmptyTitle,
      description: l10n.journalEmptyMessage(date),
      medallionIcon: Icons.calendar_today_rounded,
      fullWidthCard: true,
      primaryAction: next == null
          ? null
          : EteeloButton.secondary(
              label: l10n.journalEmptyNext(next),
              icon: Icons.arrow_forward_rounded,
              onPressed: () => onOpenDay(next),
              fullWidth: false,
            ),
    );
  }
}

/// Un journal illisible. Côté professeur la lecture est locale : la base de
/// la tablette, avec « Réessayer ». Une lecture en ligne garde les quatre
/// familles de la charte, comme le programme.
class JournalFailureView extends StatelessWidget {
  final Failure failure;
  final VoidCallback onRetry;

  const JournalFailureView({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProgrammeFailureView(
      failure: failure,
      onRetry: onRetry,
      localTitle: l10n.journalErrorTitle,
      localMessage: l10n.journalErrorMessage,
    );
  }
}
