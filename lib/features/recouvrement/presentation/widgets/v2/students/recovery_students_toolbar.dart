import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/exports/recovery_export_buttons.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_search.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_texts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'en-tête de la liste : le titre R10 en Lora (composé par le serveur) et
/// « · {n} », la ligne d'aide (`liste.aide`), la recherche, puis PDF et
/// Excel. Le titre prend sa ligne quand la place manque.
class RecoveryStudentsToolbar extends StatelessWidget {
  /// Le titre R10 ; `null` avant la première page.
  final String? title;
  final int? count;
  final RecoveryTab tab;
  final ({String ok, String ko}) verbs;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final RecoveryStudentsQuery exportQuery;
  final bool exportsEnabled;
  final String? exportsDisabledReason;

  const RecoveryStudentsToolbar({
    super.key,
    required this.title,
    required this.count,
    required this.tab,
    required this.verbs,
    required this.search,
    required this.onSearchChanged,
    required this.exportQuery,
    required this.exportsEnabled,
    required this.exportsDisabledReason,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = RecoveryStudentsTones.of(tab);
    final title = this.title;
    final count = this.count;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Text.rich(
            TextSpan(
              text: '$title ',
              children: [
                if (count != null)
                  TextSpan(
                    text: l10n.recoveryStudentsListCount(count),
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: tone,
                    ),
                  ),
              ],
            ),
            style: AppTypography.displayMedium.copyWith(
              fontSize: AppDimensions.recoveryStudentsListTitleSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              height: 1.3,
              color: AppColors.bleuProfond,
            ),
          ),
        _HelpLine(tab: tab, verbs: verbs),
      ],
    );
    final searchField = RecoveryStudentsSearch(
      search: search,
      onSearchChanged: onSearchChanged,
    );
    final exports = RecoveryExportButtons(
      query: exportQuery,
      title: title ?? '',
      enabled: exportsEnabled && title != null,
      disabledReason: exportsDisabledReason,
    );
    const gap = AppSpacing.sm + 2;
    // Comme la maquette (`flex: 1 1 280px` · `1 1 200px` · boutons) : tout
    // sur une ligne quand les bases y tiennent, sinon le titre prend la
    // sienne, puis la recherche si même elle et les boutons ne tiennent pas.
    return LayoutBuilder(
      builder: (context, c) {
        // Les boutons grandissent avec le texte (×1,3) : leur place aussi.
        final toolsWidth =
            AppDimensions.recoveryStudentsSearchMinWidth +
            gap +
            MediaQuery.textScalerOf(
              context,
            ).scale(AppDimensions.recoveryStudentsExportButtonsWidth);
        if (c.maxWidth >=
            AppDimensions.recoveryStudentsTitleMinWidth + gap + toolsWidth) {
          return Row(
            spacing: gap,
            children: [
              Expanded(flex: 28, child: heading),
              Expanded(flex: 20, child: searchField),
              exports,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: gap,
          children: [
            heading,
            if (c.maxWidth >= toolsWidth)
              Row(
                spacing: gap,
                children: [
                  Expanded(child: searchField),
                  exports,
                ],
              )
            else ...[
              searchField,
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: exports,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// « Ces élèves … : à relancer. » · « … : rien à réclamer. » · « Vert : … ·
/// Rouge : … » — les mots Vert et Rouge dans leur couleur.
class _HelpLine extends StatelessWidget {
  final RecoveryTab tab;
  final ({String ok, String ko}) verbs;

  const _HelpLine({required this.tab, required this.verbs});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final base = AppTypography.labelMedium.copyWith(
      color: AppColors.textSecondary,
    );
    final bold = base.copyWith(fontWeight: FontWeight.w700);
    final InlineSpan span = switch (tab) {
      RecoveryTab.toChase => _highlight(
        l10n.recoveryStudentsHelpToChase(verbs.ko),
        {verbs.ko: bold},
      ),
      RecoveryTab.inOrder => _highlight(
        l10n.recoveryStudentsHelpInOrder(verbs.ok),
        {verbs.ok: bold},
      ),
      RecoveryTab.all =>
        _highlight(l10n.recoveryStudentsHelpAll(verbs.ok, verbs.ko), {
          l10n.recoveryStudentsHelpAllGreen: bold.copyWith(
            color: DashboardTones.encreLisible(DashboardSense.encaisse),
          ),
          l10n.recoveryStudentsHelpAllRed: bold.copyWith(
            color: RecoveryStudentsTones.contraryInk,
          ),
        }),
    };
    return Text.rich(span, style: base);
  }

  /// Met en valeur la première occurrence de chaque fragment, sans
  /// découper la phrase traduite.
  static InlineSpan _highlight(String text, Map<String, TextStyle> marks) {
    final hits = <(int, int, TextStyle)>[];
    for (final MapEntry(key: frag, value: style) in marks.entries) {
      final at = text.indexOf(frag);
      if (frag.isNotEmpty && at >= 0) hits.add((at, at + frag.length, style));
    }
    hits.sort((a, b) => a.$1 - b.$1);
    final children = <InlineSpan>[];
    var cursor = 0;
    for (final (start, end, style) in hits) {
      if (start < cursor) continue;
      children
        ..add(TextSpan(text: text.substring(cursor, start)))
        ..add(TextSpan(text: text.substring(start, end), style: style));
      cursor = end;
    }
    children.add(TextSpan(text: text.substring(cursor)));
    return TextSpan(children: children);
  }
}
