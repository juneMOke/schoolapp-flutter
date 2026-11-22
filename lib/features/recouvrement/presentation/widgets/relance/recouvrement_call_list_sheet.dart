import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/dialog_height.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_dialog.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'aperçu nominatif d'un groupe visé — **on lit, puis on décide d'imprimer**.
///
/// La spec l'exige dans cet ordre, et il n'est pas décoratif : la liste qui sort
/// d'ici se signe et circule. Émettre au clic ferait produire un papier que
/// personne n'a lu, sur une population qu'on n'a pas vérifiée.
///
/// **Rien n'est écrit tant qu'on n'a pas appuyé sur le bouton.** Ouvrir, lire
/// et refermer ne consomme aucun numéro de pièce.
///
/// La liste à signer d'une classe de la simulation du Recouvrement v2 (O5) :
/// des [RecoveryStudentRow] déjà lus sur le serveur, une colonne « Signature
/// du parent » et les visas, plein écran sous 760 de fenêtre, et
/// « Imprimer ».
class RecouvrementCallListSheet extends StatelessWidget {
  /// Le groupe visé, tel que le classement le nomme.
  final String groupLabel;

  /// Le critère, en toutes lettres — le papier le portera aussi en sous-titre.
  final String criterionLabel;

  /// « Imprimer » : ne s'arme qu'une fois la liste lue et non vide.
  final VoidCallback? onPrint;

  /// Les élèves du mode « à signer » ; `null` pendant leur lecture.
  final List<RecoveryStudentRow>? students;

  /// La liste à signer d'une classe de la simulation (O5). [onPrint] ne
  /// s'arme qu'une fois la liste lue et non vide.
  const RecouvrementCallListSheet.students({
    super.key,
    required this.groupLabel,
    required this.criterionLabel,
    required this.students,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final rows = students;
    final fullscreen = EteeloAdaptiveDialog.isFullscreen(context);
    final body = _Body(
      loading: rows == null,
      signing: true,
      lines: [
        for (final row in rows ?? const <RecoveryStudentRow>[]) _Line.of(row),
      ],
    );
    return EteeloAdaptiveDialog(
      maxWidth: AppDimensions.recouvrementCallListMaxWidth,
      maxHeight: DialogHeight.ofWindow(context),
      child: Column(
        mainAxisSize: fullscreen ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            groupLabel: groupLabel,
            criterionLabel: criterionLabel,
            count: rows?.length ?? 0,
          ),
          if (fullscreen) Expanded(child: body) else Flexible(child: body),
          _FooterBar(
            actionLabel: AppLocalizations.of(
              context,
            )!.recoverySimulationCallListPrint,
            actionIcon: const Icon(Icons.print_outlined),
            onAction: rows != null && rows.isNotEmpty ? onPrint : null,
          ),
        ],
      ),
    );
  }
}

/// Une ligne du document, quelle que soit sa source.
class _Line {
  /// `null` quand le registre des inscriptions ne connaît pas l'élève.
  final String? name;
  final String studentId;

  /// Le matricule, sous le nom (mode « à signer »).
  final String? detail;
  final MoneyBag expected;
  final MoneyBag paid;
  final MoneyBag remaining;

  const _Line({
    required this.name,
    required this.studentId,
    this.detail,
    required this.expected,
    required this.paid,
    required this.remaining,
  });

  _Line.of(RecoveryStudentRow row)
    : this(
        name: row.displayName,
        studentId: row.studentId,
        detail: row.matriculationNumber,
        expected: MoneyBag.of(row.due),
        paid: MoneyBag.of(row.paid),
        remaining: MoneyBag.of(row.outstanding),
      );
}

class _Header extends StatelessWidget {
  final String groupLabel;
  final String criterionLabel;
  final int count;

  const _Header({
    required this.groupLabel,
    required this.criterionLabel,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recouvrementCallListTitle(groupLabel),
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            l10n.recouvrementCallListSubtitle(count, criterionLabel),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final bool loading;
  final List<_Line> lines;

  /// Colonne « Signature du parent » et visas en pied.
  final bool signing;

  const _Body({
    required this.loading,
    required this.lines,
    this.signing = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (loading) {
      // Le squelette défile comme la liste qu'il annonce : ses six lignes
      // dépassent la hauteur offerte en paysage, et une colonne figée y
      // déborderait de plus de cent pixels.
      return const SingleChildScrollView(
        padding: EdgeInsets.all(AppDimensions.spacingM),
        child: EteeloListSkeleton(rowCount: 6, showAvatar: false),
      );
    }

    if (lines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: Center(
          child: Text(
            l10n.recouvrementCallListEmpty,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final hasUnnamed = lines.any((line) => line.name == null);

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
      children: [
        const SizedBox(height: AppDimensions.spacingS),
        _ColumnHeader(signing: signing),
        for (final line in lines) _StudentRow(line: line, signing: signing),
        if (hasUnnamed) ...[
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            l10n.recouvrementCallListUnnamedNote,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
        if (signing) const _Visas(),
        const SizedBox(height: AppDimensions.spacingS),
      ],
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  final bool signing;

  const _ColumnHeader({required this.signing});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget cell(String text, int flex, {TextAlign align = TextAlign.start}) =>
        Expanded(
          flex: flex,
          child: Text(text, style: AppTextStyles.tableHeader, textAlign: align),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Row(
        children: [
          cell(l10n.recouvrementCallListStudent, 4),
          cell(l10n.recouvrementCallListDue, 3, align: TextAlign.end),
          cell(l10n.recouvrementCallListPaid, 3, align: TextAlign.end),
          cell(l10n.recouvrementCallListRemaining, 3, align: TextAlign.end),
          if (signing)
            cell(
              l10n.recoverySimulationCallListSignature,
              4,
              align: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final _Line line;
  final bool signing;

  const _StudentRow({required this.line, required this.signing});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final named = line.name;
    final detail = line.detail;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Un élève que les inscriptions ne connaissent plus garde sa
                  // dette : on l'écrit par son identifiant plutôt que de le
                  // retirer d'une liste de relance en silence.
                  named ??
                      l10n.recouvrementCallListUnnamed(
                        line.studentId.length <= 8
                            ? line.studentId
                            : line.studentId.substring(0, 8),
                      ),
                  style: named == null
                      ? AppTextStyles.body.copyWith(color: AppColors.textMuted)
                      : AppTextStyles.body,
                ),
                if (detail != null && detail.isNotEmpty)
                  Text(
                    detail,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          _amount(line.expected, 3),
          _amount(line.paid, 3),
          _amount(line.remaining, 3),
          // La case à signer : un trait sur toute sa largeur, rien d'autre.
          if (signing)
            const Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.only(left: AppDimensions.spacingS),
                child: SizedBox(
                  height: AppDimensions.minTouchTarget,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderStrong),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Une ligne par devise, empilées. **Jamais de total croisé** : en sélection
  /// mixte, dû, payé et reste s'écrivent chacun sur deux lignes.
  static Widget _amount(MoneyBag bag, int flex) => Expanded(
    flex: flex,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final entry in bag.entries)
          Text(
            MoneyFormat.format(entry),
            style: AppTextStyles.moneyTabular,
            textAlign: TextAlign.end,
          ),
      ],
    ),
  );
}

/// Les visas du percepteur et de la direction, sous la liste à signer.
class _Visas extends StatelessWidget {
  const _Visas();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget visa(String label) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          const Divider(height: 1, color: AppColors.borderStrong),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spacingL),
      child: Row(
        children: [
          visa(l10n.recoverySimulationCallListCollectorVisa),
          const SizedBox(width: AppDimensions.spacingL),
          visa(l10n.recoverySimulationCallListDirectionVisa),
        ],
      ),
    );
  }
}

class _FooterBar extends StatelessWidget {
  final VoidCallback? onAction;
  final Widget actionIcon;
  final String actionLabel;

  const _FooterBar({
    required this.onAction,
    required this.actionIcon,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.recouvrementCallListClose),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          FilledButton.icon(
            // ⚠️ Sans ce `minimumSize`, la modale entière n'a plus de taille.
            // Le thème donne aux `FilledButton` une largeur minimale infinie
            // (pensée pour les CTA pleine largeur) ; posé en enfant non-flex
            // d'un `Row`, qui offre déjà une largeur non bornée, le bouton
            // lève « BoxConstraints forces an infinite width » — l'erreur est
            // avalée au layout, et c'est le premier clic suivant qui éclate
            // sur « Cannot hit test a render box with no size ».
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, AppDimensions.minTouchTarget),
            ),
            onPressed: onAction,
            icon: actionIcon,
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
