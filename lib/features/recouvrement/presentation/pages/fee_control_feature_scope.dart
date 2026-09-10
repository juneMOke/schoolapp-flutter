import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/sync_classroom_referential_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/sync_enrollment_pulls_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/sync_finance_pulls_use_case.dart';

/// Scope BLoC du module Contrôle des frais.
///
/// Fournit sa propre instance d'[AcademicYearContextBloc] via la factory GetIt
/// — la cascade cycle/niveau du formulaire s'y alimente — et hydrate au montage
/// les trois caches locaux que l'écran interroge, sans en écrire aucun :
///  - le grand-livre ([SyncFinancePullsUseCase]) pour les créances et leur solde ;
///  - les dossiers d'inscription ([SyncEnrollmentPullsUseCase]), qui bornent la
///    population contrôlée ;
///  - le référentiel Classe ([SyncClassroomReferentialUseCase]), dont le roster
///    borne le filtre par classe. **Ne pas le retirer** : sans lui l'écran
///    consomme une table que personne ne remplit ici, et la recherche par
///    classe remonte zéro élève, silencieusement — la panne terrain du
///    2026-08-14.
///
/// **Best-effort** : lancés sans attendre, aucun échec ne remonte à l'UI, qui
/// lit le local de toute façon.
///
/// N'expose PAS d'`EnrollmentLocalListBloc`, contrairement à
/// `FinanceFeatureScope` : le contrôle a son propre bloc, qui appelle
/// `SearchLocalEnrollmentsUseCase` en direct.
///
/// ⚠️ Comme pour la Facturation, ces pulls passent par le `PullCoordinator`
/// depuis le repli ADR-015 F6 : ils sont donc filtrés par les permissions de la
/// session. Un rôle qui a `finance.charge.read` sans `enrollment.read` verra sa
/// recherche rester vide, et cela se lit dans `PullRunReport.forbidden` — pas
/// dans une erreur. L'écran le dit à sa façon, par ses états vides.
class FeeControlFeatureScope extends StatefulWidget {
  final Widget child;

  const FeeControlFeatureScope({super.key, required this.child});

  @override
  State<FeeControlFeatureScope> createState() => _FeeControlFeatureScopeState();
}

class _FeeControlFeatureScopeState extends State<FeeControlFeatureScope> {
  late final AcademicYearContextBloc _academicYearContextBloc;

  @override
  void initState() {
    super.initState();
    _academicYearContextBloc = GetIt.instance<AcademicYearContextBloc>();
    unawaited(GetIt.instance<SyncFinancePullsUseCase>()());
    unawaited(GetIt.instance<SyncEnrollmentPullsUseCase>()());
    unawaited(GetIt.instance<SyncClassroomReferentialUseCase>()());
  }

  @override
  void dispose() {
    _academicYearContextBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AcademicYearContextBloc>.value(
      value: _academicYearContextBloc,
      child: widget.child,
    );
  }
}
