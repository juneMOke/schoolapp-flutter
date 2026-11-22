import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_dialog.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/domain/repositories/fee_control_export_repository.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_query_phrase.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/exports/recovery_export_error_state.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/reports/cash_report_viewer.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le segment de l'écran, tel que le serveur le vérifie.
FeeControlExportFilter feeControlExportFilterOf(FeeControlPaymentFilter f) =>
    switch (f) {
      FeeControlPaymentFilter.all => FeeControlExportFilter.all,
      FeeControlPaymentFilter.none => FeeControlExportFilter.noPayment,
      FeeControlPaymentFilter.partial => FeeControlExportFilter.partial,
      FeeControlPaymentFilter.settled => FeeControlExportFilter.settled,
      FeeControlPaymentFilter.threshold => FeeControlExportFilter.paidAtLeast,
    };

/// Ouvre l'export PDF / Excel du **résultat entier** du contrôle des frais
/// (R11, O5) : toutes les pages, sur la même question (frais, classe,
/// situation). La tablette envoie ses lignes, le serveur imprime ; vert : tout
/// soldé (ou « a payé au moins » sous ce segment), rouge : à relancer.
///
/// Les lignes sont **figées à l'ouverture** : basculer PDF | Excel imprime la
/// même liste, et chaque format n'est demandé qu'une fois (un PDF consomme
/// un numéro de pièce).
Future<void> openFeeControlExport(
  BuildContext context,
  RecoveryExportFormat format,
) {
  final bloc = context.read<FeeControlBloc>();
  final query = bloc.state.lastQuery;
  // Pendant un rechargement, `results` porte encore les lignes de l'ancienne
  // question (I4) : rien ne part hors d'un résultat servi.
  if (bloc.state.status != EnrollmentLoadStatus.success) return Future.value();
  if (query == null || bloc.results.isEmpty) return Future.value();
  // Sous « a payé au moins… », le seuil part toujours avec sa devise, 0
  // compris (R3) ; sans seuil résolu (mixte), le serveur refuserait.
  if (query.statusFilter.needsThreshold && query.threshold == null) {
    return Future.value();
  }
  final l10n = AppLocalizations.of(context)!;
  final titles = context.read<FeeSectionTitlesCubit>().state;
  final lines = [for (final row in bloc.results) row.line];
  final title = l10n.feeControlExportTitle(
    FeeControlQueryPhrase.parts(bloc.state, l10n, titles: titles).join(' · '),
  );
  final repository = getIt<FeeControlExportRepository>();
  FocusManager.instance.primaryFocus?.unfocus();
  return showEteeloAdaptiveDialog<void>(
    context: context,
    builder: (_) => CashReportViewer(
      reportId: l10n.feeControlExportReference,
      title: title,
      initialFormat: format == RecoveryExportFormat.pdf
          ? CashReportFormat.pdf
          : CashReportFormat.xlsx,
      errorBuilder: (failure, retry) =>
          RecoveryExportErrorState(failure: failure, onRetry: retry),
      loader: (cash) async {
        final result = await repository.export(
          classroomId: query.classroomId,
          feeCodes: query.feeCodes,
          filter: feeControlExportFilterOf(query.statusFilter),
          // Résolu sur la devise des lignes exportées (B2-B3).
          threshold: query.threshold,
          lines: lines,
          format: cash == CashReportFormat.pdf
              ? RecoveryExportFormat.pdf
              : RecoveryExportFormat.xlsx,
        );
        return result.map(
          (file) => CashReportFile(
            bytes: file.bytes,
            fileName: file.fileName,
            format: cash,
          ),
        );
      },
    ),
  );
}
