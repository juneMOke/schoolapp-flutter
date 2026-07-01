import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/cours_notation_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/cours_notation_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/cours_notation_state.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_labels.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_back_bar.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_bucket_panel.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_bucket_timeline.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_detail_header_card.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_detail_skeleton.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_periode_tabs.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_releve_modal.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/states/cours_notation_results_empty_state.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/states/cours_notation_results_error_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Page détail d'un cours (spec « Détail-Cours ») : en-tête → onglets de période
/// → frise de buckets → panneau de la sélection. Lecture seule. La création
/// d'évaluation (FAB) et la saisie des notes ne sont pas câblées (différées).
class CoursNotationDetailPage extends StatelessWidget {
  final CoursDetailArgs args;
  final VoidCallback onBack;

  const CoursNotationDetailPage({
    super.key,
    required this.args,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CoursNotationBloc>(
      create: (_) =>
          GetIt.instance<CoursNotationBloc>()
            ..add(CoursNotationRequested(coursId: args.coursId)),
      child: _CoursNotationDetailView(args: args, onBack: onBack),
    );
  }
}

class _CoursNotationDetailView extends StatefulWidget {
  final CoursDetailArgs args;
  final VoidCallback onBack;

  const _CoursNotationDetailView({required this.args, required this.onBack});

  @override
  State<_CoursNotationDetailView> createState() =>
      _CoursNotationDetailViewState();
}

class _CoursNotationDetailViewState extends State<_CoursNotationDetailView> {
  /// `null` = sélection par défaut (résolue à partir du view-model).
  int? _periodeIdx;
  String? _bucketKey;

  void _selectPeriode(int index) {
    setState(() {
      _periodeIdx = index;
      _bucketKey = null; // re-sélectionne la période courante du nouvel onglet.
    });
  }

  void _selectBucket(String key) => setState(() => _bucketKey = key);

  void _retry() => context.read<CoursNotationBloc>().add(
    CoursNotationRequested(coursId: widget.args.coursId),
  );

  Future<void> _contactAdmin() async {
    await launchUrl(Uri(scheme: 'mailto', path: AppConstants.supportEmail));
    if (!mounted)
      return; // garde mounted après await (règle non-négociable #8).
  }

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CoursBackBar(
            brancheNom: widget.args.brancheNom,
            classroomName: widget.args.classroomName,
            onBack: widget.onBack,
          ),
          const SizedBox(height: AppSpacing.xl),
          BlocBuilder<CoursNotationBloc, CoursNotationState>(
            buildWhen: (prev, curr) =>
                prev.status != curr.status ||
                prev.detail != curr.detail ||
                prev.errorType != curr.errorType,
            builder: (context, state) {
              return AnimatedSize(
                duration: AppMotion.standard,
                curve: AppMotion.outCurve,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: AppMotion.standard,
                  switchInCurve: AppMotion.outCurve,
                  switchOutCurve: AppMotion.inCurve,
                  child: KeyedSubtree(
                    key: ValueKey<String>(
                      '${state.status.name}-${state.errorType.name}',
                    ),
                    child: _buildBody(context, state),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, CoursNotationState state) {
    return switch (state.status) {
      CoursNotationStatus.initial ||
      CoursNotationStatus.loading => const CoursDetailSkeleton(),
      CoursNotationStatus.failure => CoursNotationResultsErrorState(
        type: state.errorType,
        onRetry: _retry,
        onReconnect: () =>
            context.read<AuthBloc>().add(const AuthLogoutRequested()),
        onContactAdmin: _contactAdmin,
      ),
      CoursNotationStatus.success =>
        state.detail == null
            ? const CoursNotationResultsEmptyState()
            : _buildReady(context, state.detail!),
    };
  }

  Widget _buildReady(BuildContext context, CoursNotationDetail detail) {
    final l10n = AppLocalizations.of(context)!;
    final vm = CoursNotationViewModel.fromDetail(detail, now: DateTime.now());
    final brancheNom = detail.brancheNom?.trim().isNotEmpty == true
        ? detail.brancheNom!
        : widget.args.brancheNom;

    final header = CoursDetailHeaderCard(
      brancheNom: brancheNom,
      classroomName: widget.args.classroomName,
      visual: widget.args.visual,
      viewModel: vm,
    );

    if (vm.isEmpty) {
      // En-tête réel + état vide (spec §11 : « Aucune évaluation »).
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: AppSpacing.lg),
          const CoursNotationResultsEmptyState(),
        ],
      );
    }

    final periodeIdx = (_periodeIdx ?? vm.defaultPeriodeIndex).clamp(
      0,
      vm.periodes.length - 1,
    );
    final periode = vm.periodes[periodeIdx];
    final bucketKey = _bucketKey ?? periode.defaultBucketKey;
    final bucket = _resolveBucket(periode, bucketKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: AppSpacing.lg),
        CoursPeriodeTabs(
          periodes: vm.periodes,
          selectedIndex: periodeIdx,
          onSelect: _selectPeriode,
        ),
        const SizedBox(height: AppSpacing.md),
        if (periode.buckets.isNotEmpty)
          CoursBucketTimeline(
            buckets: periode.buckets,
            selectedKey: bucket?.key ?? '',
            onSelect: _selectBucket,
          ),
        const SizedBox(height: AppSpacing.md),
        if (bucket != null)
          CoursBucketPanel(
            key: ValueKey<String>('panel-${bucket.key}'),
            bucket: bucket,
            onOpenReleve: () => showCoursReleveModal(
              context,
              brancheNom: brancheNom,
              classroomName: widget.args.classroomName,
              label: bucketLabel(l10n, bucket),
              bucket: bucket,
            ),
          ),
      ],
    );
  }

  BucketVm? _resolveBucket(PeriodeVm periode, String? key) {
    if (periode.buckets.isEmpty) return null;
    for (final b in periode.buckets) {
      if (b.key == key) return b;
    }
    return periode.buckets.first;
  }
}
