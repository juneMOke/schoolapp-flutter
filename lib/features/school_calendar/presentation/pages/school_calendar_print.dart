import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/school/presentation/cubit/school_identity_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/export/school_calendar_pdf.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_weekday_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// O7 — imprimer la version publiée ou archivée (CAL-R17), composée sur
/// l'appareil (K14) : la même page en ligne et hors ligne. Un brouillon ne
/// s'imprime pas — l'écran ne propose pas « Imprimer ».
Future<void> printSchoolCalendar(
  BuildContext context,
  SchoolCalendarState state,
) async {
  final calendar = state.calendar;
  if (calendar == null || !calendar.isPublished) return;
  final l10n = AppLocalizations.of(context)!;
  final dates = MaterialLocalizations.of(context);
  final published = calendar.publishedAt;
  final school = context.read<SchoolIdentityCubit?>()?.state.school?.name ?? '';
  final labels = SchoolCalendarPdfLabels(
    schoolName: school,
    title: l10n.schoolCalendarPdfTitle(calendar.yearLabel),
    range: CalendarLabels.range(context, calendar.startDate, calendar.endDate),
    publishedOn: published == null
        ? ''
        : l10n.schoolCalendarPdfPublished(dates.formatMediumDate(published)),
    keyDatesTitle: l10n.schoolCalendarPdfKeyDates,
    nationalNote: l10n.schoolCalendarPdfNationalNote,
    printedOn: l10n.schoolCalendarPdfPrinted(
      dates.formatMediumDate(SchoolTime.today(DateTime.now())),
    ),
    brand: 'ETEELO CONNECT',
    weekdayInitials: CalendarWeekdayLabels.of(context, compact: true),
    monthName: dates.formatMonthYear,
    natureName: (n) => CalendarLabels.natureShort(l10n, n),
    dates: (e) => CalendarLabels.dates(context, e),
  );
  try {
    final bytes = await SchoolCalendarPdf.build(
      startDate: calendar.startDate,
      endDate: calendar.endDate,
      elements: state.allElements,
      labels: labels,
    );
    if (!context.mounted) return;
    await showEteeloDocumentViewer(
      context,
      title: l10n.schoolCalendarPrintTitle,
      document: PrintableDocument(
        bytes: bytes,
        fileName: SchoolCalendarPdf.fileName(calendar.yearLabel),
      ),
    );
  } catch (_) {
    if (context.mounted) {
      AppSnackBar.showError(context, l10n.schoolCalendarPrintFailed);
    }
  }
}

/// Le document officiel du ministère (contrat du 2026-11-20) : servi tel quel
/// par le serveur, sans numéro ni scellé, ouvert dans la visionneuse.
Future<void> openFrameworkDocument(
  BuildContext context,
  SchoolCalendarCubit cubit,
) async {
  final year = cubit.state.calendar?.yearLabel;
  if (year == null) return;
  final l10n = AppLocalizations.of(context)!;
  final result = await cubit.frameworkDocument();
  if (!context.mounted) return;
  await result.fold(
    (_) async => AppSnackBar.showError(
      context,
      l10n.schoolCalendarOfficialDocumentFailed,
      onRetry: () => openFrameworkDocument(context, cubit),
    ),
    (document) => showEteeloDocumentViewer(
      context,
      title: l10n.schoolCalendarOfficialDocumentTitle(year),
      document: document,
    ),
  );
}
