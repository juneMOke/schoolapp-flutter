import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/disciplinary_case_helpers.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_view_dialog.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_cases_state_body.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class DisciplinaryCasesTab extends StatelessWidget {
  final String studentId;
  final String academicYearId;
  /// Callback déclenché depuis l'état vide pour créer un premier cas.
  final VoidCallback? onCreateCase;

  const DisciplinaryCasesTab({
    super.key,
    required this.studentId,
    required this.academicYearId,
    this.onCreateCase,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<DisciplinaryCaseBloc, DisciplinaryCaseState>(
      buildWhen: (prev, curr) =>
          prev.listStatus != curr.listStatus ||
          prev.listErrorType != curr.listErrorType ||
          prev.cases != curr.cases,
      builder: (context, state) {
        final bodyStatus = switch (state.listStatus) {
          DisciplinaryCaseStatusState.loading =>
            DisciplinaryCasesBodyStatus.loading,
          DisciplinaryCaseStatusState.success when state.cases.isEmpty =>
            DisciplinaryCasesBodyStatus.empty,
          DisciplinaryCaseStatusState.success =>
            DisciplinaryCasesBodyStatus.success,
          DisciplinaryCaseStatusState.failure =>
            DisciplinaryCasesBodyStatus.error,
          DisciplinaryCaseStatusState.initial =>
            DisciplinaryCasesBodyStatus.loading,
        };

        return DisciplinaryCasesStateBody(
          status: bodyStatus,
          cases: state.cases,
          errorMessage: DisciplinaryCaseHelpers.mapErrorType(
            l10n,
            state.listErrorType,
          ),
          onRetry: () => _retryList(context),
          onViewCase: (caseData) => _showViewDialog(context, caseData.id),
          onCreateCase: onCreateCase,
        );
      },
    );
  }

  void _retryList(BuildContext context) {
    context.read<DisciplinaryCaseBloc>().add(
      DisciplinaryCaseListRequested(
        studentId: studentId,
        academicYearId: academicYearId,
      ),
    );
  }

  void _showViewDialog(BuildContext context, String caseId) {
    final disciplinaryCaseBloc = context.read<DisciplinaryCaseBloc>();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => BlocProvider<DisciplinaryCaseBloc>.value(
        value: disciplinaryCaseBloc,
        child: DisciplinaryCaseViewDialog(
          caseId: caseId,
          studentId: studentId,
          title: l10n.disciplinaryCaseViewDialogTitle,
        ),
      ),
    );
  }
}
