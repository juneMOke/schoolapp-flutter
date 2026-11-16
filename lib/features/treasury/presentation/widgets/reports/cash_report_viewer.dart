import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_dialog.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_pdf_preview.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/treasury/data/xlsx/xlsx_workbook.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_reports_repository.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_tones.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/reports/cash_report_viewer_footer.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/reports/xlsx_sheet_view.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/states/treasury_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La visionneuse d'un rapport de caisse (A6) : une bascule PDF | Excel, le
/// document du format choisi — page PDF ou aperçu de la feuille —, et ses
/// gestes (imprimer et partager le PDF, enregistrer la feuille). Chaque
/// fichier est demandé au serveur la première fois qu'on le montre.
class CashReportViewer extends StatefulWidget {
  final String reportId;
  final String title;
  final CashReportFormat initialFormat;
  final TreasuryReportsRepository repository;

  /// Couture de test : la page PDF se rasterise par canal de plateforme et ne
  /// se monte pas en test widget.
  final Widget Function(CashReportFile file)? pdfPreviewBuilder;

  const CashReportViewer({
    super.key,
    required this.reportId,
    required this.title,
    required this.initialFormat,
    required this.repository,
    this.pdfPreviewBuilder,
  });

  @override
  State<CashReportViewer> createState() => _CashReportViewerState();
}

class _Loaded {
  final CashReportFile? file;
  final XlsxWorkbook? workbook;
  final Failure? failure;

  /// La feuille est arrivée mais ne se lit pas : on peut toujours
  /// l'enregistrer.
  final bool unreadable;

  const _Loaded({
    this.file,
    this.workbook,
    this.failure,
    this.unreadable = false,
  });
}

class _CashReportViewerState extends State<CashReportViewer> {
  late var _format = widget.initialFormat;
  final _loaded = <CashReportFormat, _Loaded>{};

  @override
  void initState() {
    super.initState();
    _load(_format);
  }

  Future<void> _load(CashReportFormat format) async {
    setState(() => _loaded.remove(format));
    final result = await widget.repository.file(widget.reportId, format);
    if (!mounted) return;
    final loaded = result.fold((failure) => _Loaded(failure: failure), (file) {
      if (file.format != CashReportFormat.xlsx) return _Loaded(file: file);
      try {
        return _Loaded(file: file, workbook: XlsxWorkbook.read(file.bytes));
      } on FormatException {
        return _Loaded(file: file, unreadable: true);
      }
    });
    setState(() => _loaded[format] = loaded);
  }

  void _switch(CashReportFormat format) {
    setState(() => _format = format);
    if (!_loaded.containsKey(format)) _load(format);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screen = MediaQuery.sizeOf(context);
    final loaded = _loaded[_format];
    final file = loaded?.file;
    final provisional = file?.status == CashReportStatus.provisional;
    return EteeloAdaptiveDialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      // La feuille prend presque tout l'écran : un rapport a onze colonnes,
      // l'onglet « Données » dix-sept. La page PDF garde sa largeur.
      maxWidth: _format == CashReportFormat.xlsx
          ? screen.width
          : (screen.width * AppDimensions.documentViewerWidthRatio)
                .clamp(
                  AppDimensions.documentViewerMaxWidth,
                  AppDimensions.documentViewerWideMaxWidth,
                )
                .toDouble(),
      maxHeight: screen.height * AppDimensions.dialogMaxHeightRatio,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DocumentViewerHeader(
            title: widget.title,
            subtitle: provisional
                ? l10n.treasuryReportProvisionalRef(widget.reportId)
                : widget.reportId,
            onClose: () => Navigator.of(context).maybePop(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: SegmentedTabFilter<CashReportFormat>(
                style: TreasuryTones.filter,
                semanticsLabel: l10n.treasuryReportFormat,
                selected: _format,
                onSelected: _switch,
                options: [
                  SegmentedTabOption(
                    label: l10n.treasuryReportPdf,
                    value: CashReportFormat.pdf,
                    icon: Icons.description_outlined,
                  ),
                  SegmentedTabOption(
                    label: l10n.treasuryReportExcel,
                    value: CashReportFormat.xlsx,
                    icon: Icons.grid_on,
                  ),
                ],
              ),
            ),
          ),
          if (provisional)
            Container(
              margin: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.treasuryPendingSoft,
                border: Border.all(color: AppColors.treasuryPendingBorder),
                borderRadius: BorderRadius.circular(
                  AppDimensions.treasuryFormatButtonRadius,
                ),
              ),
              child: Text(
                l10n.treasuryViewerProvisional,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.treasuryPendingInk,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.border),
          Expanded(child: _body(l10n, loaded)),
          const Divider(height: 1, color: AppColors.border),
          CashReportViewerFooter(format: _format, file: file),
        ],
      ),
    );
  }

  Widget _body(AppLocalizations l10n, _Loaded? loaded) {
    if (loaded == null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: EteeloListSkeleton(
          rowCount: 6,
          pillCount: 0,
          showAvatar: false,
          semanticsLabel: l10n.treasuryViewerLoading,
        ),
      );
    }
    final failure = loaded.failure;
    // 429 : un autre rendu long tourne sur le serveur ; ce n'est pas une
    // panne, il suffit de réessayer dans un instant.
    if (failure is TooManyRequestsFailure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.treasuryReportBusy,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              EteeloButton.secondary(
                label: l10n.treasuryRetry,
                icon: Icons.refresh,
                onPressed: () => _load(_format),
                fullWidth: false,
              ),
            ],
          ),
        ),
      );
    }
    if (failure != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: TreasuryResultsErrorState(
          failure: failure,
          onRetry: () => _load(_format),
        ),
      );
    }
    final file = loaded.file!;
    if (_format == CashReportFormat.pdf) {
      final builder = widget.pdfPreviewBuilder;
      return builder != null
          ? builder(file)
          : EteeloPdfPreview(bytes: file.bytes, fileName: file.fileName);
    }
    final workbook = loaded.workbook;
    if (workbook == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            l10n.treasuryXlsxUnreadable,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    return XlsxWorkbookView(workbook: workbook);
  }
}
