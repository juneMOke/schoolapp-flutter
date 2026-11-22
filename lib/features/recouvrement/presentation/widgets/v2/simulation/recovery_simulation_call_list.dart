import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_dialog.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_dashboard_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_students_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/v2/recovery_dashboard_actions.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/relance/recouvrement_call_list_sheet.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_class_name.dart';

/// La taille d'une page lue pour la liste à signer : une classe y tient
/// d'ordinaire en une seule.
const int recoveryCallListPageSize = 100;

/// O5 · la liste nominative d'une classe de la simulation : ses élèves
/// **visés** (onglet « À relancer » de la règle posée), à signer.
///
/// La feuille s'ouvre tout de suite sur des lignes fantômes ; une erreur de
/// lecture la referme et se dit par un message — jamais une feuille vide.
/// « Imprimer » ouvre la pièce composée par le serveur (O3, PDF) sur la même
/// question : le papier nominatif ne se compose jamais sur l'appareil.
Future<void> showRecoverySimulationCallList(
  BuildContext context, {
  required String academicYearId,
  required RecoveryQuestion question,
  required RecoverySimulationRow row,
  required String criterionLabel,
}) async {
  if (row.targetedStudents <= 0) return;
  FocusManager.instance.primaryFocus?.unfocus();
  final l10n = AppLocalizations.of(context)!;
  final cubit = getIt<RecoveryStudentsCubit>();
  final query = RecoveryStudentsQuery(
    question: question,
    tab: RecoveryTab.toChase,
    classroomId: row.classroomId ?? recoveryUnassigned,
    size: recoveryCallListPageSize,
  );
  final loading = loadRecoveryCallList(cubit, academicYearId, query);
  final failure = await showEteeloAdaptiveDialog<Failure>(
    context: context,
    builder: (dialogContext) => _CallListLoader(
      loading: loading,
      groupLabel: row.displayName(l10n),
      criterionLabel: criterionLabel,
      onPrint: (title) => openRecoveryExport(
        dialogContext,
        query: query,
        format: RecoveryExportFormat.pdf,
        title: title,
      ),
    ),
  );
  await cubit.close();
  if (failure == null || !context.mounted) return;
  AppSnackBar.showError(context, recoveryCallListFailureText(failure, l10n));
}

/// Les élèves visés, toutes pages lues, et le titre R10 du serveur ; ou
/// l'échec de la première lecture qui a échoué.
typedef RecoveryCallList = ({
  List<RecoveryStudentRow> rows,
  String title,
  Failure? failure,
});

/// Lit page après page jusqu'à la dernière : une liste à signer qui
/// s'arrêterait à la centième ligne ferait disparaître des familles.
Future<RecoveryCallList> loadRecoveryCallList(
  RecoveryStudentsCubit cubit,
  String academicYearId,
  RecoveryStudentsQuery query,
) async {
  final rows = <RecoveryStudentRow>[];
  var title = '';
  var page = 0;
  while (true) {
    await cubit.load(academicYearId, query.copyWith(page: page));
    final state = cubit.state;
    final received = state.page;
    if (state.status != RecoveryLoadStatus.success || received == null) {
      return (
        rows: const <RecoveryStudentRow>[],
        title: title,
        failure: state.failure ?? const ServerFailure(),
      );
    }
    rows.addAll(received.content);
    title = received.title;
    page++;
    if (page >= received.totalPages || received.content.isEmpty) break;
  }
  return (rows: rows, title: title, failure: null);
}

/// Le message d'un échec de lecture, par famille (règle n° 10).
String recoveryCallListFailureText(Failure failure, AppLocalizations l10n) =>
    switch (EteeloErrorType.fromFailure(failure)) {
      EteeloErrorType.network => l10n.recoveryErrorNetwork,
      EteeloErrorType.unauthorized => l10n.recoveryErrorUnauthorized,
      EteeloErrorType.forbidden => l10n.recoveryErrorForbiddenList,
      _ => l10n.recoveryErrorServer,
    };

class _CallListLoader extends StatefulWidget {
  final Future<RecoveryCallList> loading;
  final String groupLabel;
  final String criterionLabel;
  final ValueChanged<String> onPrint;

  const _CallListLoader({
    required this.loading,
    required this.groupLabel,
    required this.criterionLabel,
    required this.onPrint,
  });

  @override
  State<_CallListLoader> createState() => _CallListLoaderState();
}

class _CallListLoaderState extends State<_CallListLoader> {
  RecoveryCallList? _list;

  @override
  void initState() {
    super.initState();
    _await();
  }

  Future<void> _await() async {
    final list = await widget.loading;
    if (!mounted) return;
    if (list.failure case final failure?) {
      Navigator.of(context).pop(failure);
      return;
    }
    setState(() => _list = list);
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    return RecouvrementCallListSheet.students(
      groupLabel: widget.groupLabel,
      criterionLabel: widget.criterionLabel,
      students: list?.rows,
      onPrint: list == null ? null : () => widget.onPrint(list.title),
    );
  }
}
