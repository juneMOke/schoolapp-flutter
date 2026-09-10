import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_level_labels.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_selection_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/export/fee_control_call_sheet_pdf.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_query_phrase.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/fiche/fee_control_student_sheet.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Les gestes qui **sortent** de l'écran nominatif : ouvrir un aperçu, marquer
/// un lot, éditer la feuille d'appel, rejoindre la fiche financière.
///
/// Ils vivent ici et non dans la page parce qu'ils ne dessinent rien : ils
/// lisent deux blocs, composent, et partent ailleurs. La page, elle, n'a qu'à
/// les appeler — et redescend sous la cible de longueur que le projet se donne.

/// Ouvre l'**aperçu** d'un élève : ses frais retenus, un par un.
///
/// L'aperçu lit ; la fiche financière de la Facturation, elle, agit — et son
/// bouton la rejoint. Les deux ne s'empilent jamais : l'aperçu se referme
/// avant.
Future<void> openStudentSheet(
  BuildContext context,
  FeeControlRow row,
  String academicYearId,
) async {
  final l10n = AppLocalizations.of(context)!;
  final selection = context.read<FeeControlSelectionCubit>();
  final bloc = context.read<FeeControlBloc>();
  final name =
      '${row.summary.student.lastName} ${row.summary.student.firstName}';

  final openRecord = await showDialog<bool>(
    context: context,
    builder: (dialogContext) =>
        BlocBuilder<FeeControlSelectionCubit, FeeControlSelectionState>(
          bloc: selection,
          builder: (_, state) => FeeControlStudentSheet(
            row: row,
            tariffs: bloc.state.tariffs,
            rate: bloc.state.lastQuery?.rate,
            marked: state.marked.contains(row.studentId),
            onToggleMark: () {
              final wasMarked = state.marked.contains(row.studentId);
              selection.toggleMark(row.studentId);
              Navigator.of(dialogContext).pop(false);
              AppSnackBar.showInfo(
                context,
                wasMarked
                    ? l10n.feeControlSheetUnmarked(name)
                    : l10n.feeControlSheetMarked(name),
              );
            },
            onOpenRecord: () => Navigator.of(dialogContext).pop(true),
          ),
        ),
  );

  if (openRecord != true || !context.mounted) return;
  openFinancialRecord(context, row, academicYearId);
}

/// Ajoute les élèves cochés à la liste de travail des renvois.
///
/// **Rien n'est écrit.** Le geste est additif — marquer deux fois n'empile
/// rien — et il consomme la sélection : une fois portés sur la liste, les
/// élèves n'ont plus à rester cochés.
void markSelection(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final cubit = context.read<FeeControlSelectionCubit>();
  final ids = cubit.state.selected;
  if (ids.isEmpty) return;
  final count = ids.length;
  cubit.mark(ids);
  AppSnackBar.showInfo(context, l10n.feeControlMarkedDone(count));
}

/// Édite la **feuille d'appel** des élèves cochés, et l'envoie à l'impression.
///
/// La population est prise dans le résultat ENTIER et dans **son ordre** : un
/// élève coché page 1 doit figurer sur la feuille éditée page 3, et la
/// numérotation imprimée doit se relire comme l'écran.
///
/// `Printing.layoutPdf` plutôt que `sharePdf` : le second écrit le document en
/// clair dans le cache de l'appareil, et cette feuille est nominative.
Future<void> printCallSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final selected = context.read<FeeControlSelectionCubit>().state.selected;
  final bloc = context.read<FeeControlBloc>();
  final rows = [
    for (final row in bloc.results)
      if (selected.contains(row.studentId)) row,
  ];
  if (rows.isEmpty) return;

  final academicYear = context
      .read<AcademicYearContextBloc>()
      .state
      .context
      ?.academicYear;

  final bytes = await FeeControlCallSheetPdf.build(
    rows: rows,
    context: FeeControlQueryPhrase.parts(bloc.state, l10n).join(' · '),
    academicYearLabel: academicYear?.name ?? '',
    issuedOn: DateTime.now(),
    rate: bloc.state.lastQuery?.rate,
    l10n: l10n,
  );

  await Printing.layoutPdf(onLayout: (_) async => bytes);
}

/// Ouvre la **Facturation**. L'issue d'un écran où personne n'a payé n'est pas
/// de re-chercher : c'est d'encaisser.
void openBilling(BuildContext context) {
  context.push(AppRoutesNames.facturations);
}

/// Ouvre la fiche financière de l'élève — la page de détail de la Facturation,
/// réutilisée telle quelle. Le retour revient ici : la page est **poussée**, et
/// `StudentDetailAppBar` dépile avant de retomber sur sa route de repli.
void openFinancialRecord(
  BuildContext context,
  FeeControlRow row,
  String academicYearId,
) {
  final l10n = AppLocalizations.of(context)!;
  if (academicYearId.isEmpty) {
    AppSnackBar.showWarning(context, l10n.bootstrapContextUnavailableMessage);
    return;
  }

  final levelId = context.read<FeeControlBloc>().state.lastQuery?.schoolLevelId;
  final academicYearContext = context
      .read<AcademicYearContextBloc>()
      .state
      .context;

  // Troisième porte sur la MÊME fiche que Facturation et son sur-titre : les
  // frais contrôlés imposent déjà une classe, mais la ligne reste la source la
  // plus sûre quand le référentiel n'est pas encore descendu.
  final labels = resolveEnrollmentLevelLabels(
    row.summary,
    bundles: academicYearContext?.schoolLevelGroups ?? const [],
    searchedLevelId: levelId ?? '',
  );

  final student = row.summary.student;
  context.push(
    AppRoutesNames.facturationDetailPath(
      studentId: student.id,
      academicYearId: academicYearId,
    ),
    extra: FacturationDetailIntent(
      studentId: student.id,
      academicYearId: academicYearId,
      firstName: student.firstName,
      lastName: student.lastName,
      surname: student.surname,
      levelName: labels.levelName,
      levelGroupName: labels.levelGroupName,
    ),
  );
}
