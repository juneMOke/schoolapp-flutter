import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/wizard/wizard_step_progression.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_catalog.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_plan.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_draft_repository.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_repository.dart';

part 'configuration_event.dart';
part 'configuration_state.dart';

/// Le parcours de mise en service : progression, brouillon et simulation.
///
/// L'étape 1 n'est **pas** ici : elle écrit réellement sur `/schools/{id}`,
/// n'entre jamais dans le brouillon, et n'a rien à simuler. La mêler à ce bloc
/// aurait confondu deux régimes de persistance — c'est précisément ce que la
/// barre de pied doit distinguer à l'écran (« Enregistré » contre « Brouillon
/// enregistré »).
class ConfigurationBloc extends Bloc<ConfigurationEvent, ConfigurationState> {
  final ProvisioningRepository _repository;
  final ProvisioningDraftRepository _draftRepository;

  /// Temporisation avant simulation. Chaque coche appellerait sinon le serveur.
  final Duration simulationDebounce;

  Timer? _simulationTimer;

  /// Anti-course, même idiome que `AcademicYearContextBloc` : deux événements
  /// d'un même bloc s'exécutent en concurrence. Une simulation lancée sur un
  /// brouillon déjà périmé ne doit jamais écraser le plan d'une plus récente —
  /// l'écran afficherait alors des totaux qui ne correspondent à rien de ce
  /// qui est coché.
  int _simulationGeneration = 0;

  ConfigurationBloc({
    required ProvisioningRepository repository,
    required ProvisioningDraftRepository draftRepository,
    this.simulationDebounce = const Duration(milliseconds: 450),
  }) : _repository = repository,
       _draftRepository = draftRepository,
       super(const ConfigurationState()) {
    on<ConfigurationStarted>(_onStarted);
    on<ConfigurationStepSelected>(_onStepSelected);
    on<ConfigurationContinueRequested>(_onContinueRequested);
    on<ConfigurationBackRequested>(_onBackRequested);
    on<ConfigurationSaveRequested>(_onSaveRequested);
    on<ConfigurationDraftChanged>(_onDraftChanged);
    on<ConfigurationRetryRequested>(_onRetryRequested);
    on<ConfigurationSimulationRequested>(_onSimulationRequested);
  }

  /// Étape de reprise, **bornée**.
  ///
  /// Un brouillon écrit par une version future de l'application, ou simplement
  /// abîmé, peut porter un rang qui n'existe pas ici. Y accéder par index
  /// lèverait au moment précis où l'assistant s'ouvre — l'agent se retrouverait
  /// devant un écran mort, avec sa saisie intacte et inaccessible.
  static ConfigurationStep _stepAt(int rank) {
    if (rank < 0) return ConfigurationStep.school;
    if (rank >= ConfigurationStep.count) return ConfigurationStep.activation;
    return ConfigurationStep.values[rank];
  }

  @override
  Future<void> close() {
    _simulationTimer?.cancel();
    return super.close();
  }

  Future<void> _onStarted(
    ConfigurationStarted event,
    Emitter<ConfigurationState> emit,
  ) async {
    emit(state.copyWith(status: ConfigurationStatus.loading, failure: null));

    // Le brouillon d'abord : il décide de l'étape sur laquelle l'assistant
    // rouvre, et une lecture locale ne peut pas échouer bruyamment.
    final draft = await _draftRepository.load();

    final catalogResult = await _repository.loadCatalog();
    final feeCodesResult = await _repository.loadFeeCodes();

    final failure = catalogResult.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      emit(
        state.copyWith(
          status: ConfigurationStatus.failure,
          failure: failure,
          draft: draft?.request,
          step: draft == null ? null : _stepAt(draft.step),
          maxStep: draft?.maxStep,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ConfigurationStatus.ready,
        catalog: catalogResult.getOrElse(() => throw StateError('unreachable')),
        // Le catalogue de frais n'est pas bloquant : l'assistant s'ouvre sans
        // lui, et seule l'étape 4 en a besoin. La faire échouer à l'entrée
        // fermerait tout le parcours pour une route qui ne sert qu'au bout.
        feeCodes: feeCodesResult.getOrElse(() => const <FeeCodeOption>[]),
        draft: draft?.request,
        step: draft == null ? null : _stepAt(draft.step),
        maxStep: draft?.maxStep,
        failure: null,
      ),
    );

    if (state.draft.isSimulatable) {
      add(const ConfigurationSimulationRequested());
    }
  }

  void _onStepSelected(
    ConfigurationStepSelected event,
    Emitter<ConfigurationState> emit,
  ) {
    // Le stepper décide déjà de ce qui est cliquable, mais un saut peut aussi
    // venir d'un raccourci « Modifier » du récapitulatif ou d'un contrôle en
    // ambre : la borne se tient donc ici, où tous les chemins passent.
    if (!state.progression.statusAt(event.step.rank).canTap) return;
    emit(
      state.copyWith(
        step: event.step,
        maxStep: event.step.rank > state.maxStep ? event.step.rank : null,
        // La coche du pied ne survit pas au changement d'étape : elle atteste
        // d'un enregistrement, pas d'un état durable.
        justSaved: false,
        failure: null,
        status: state.hasFailure ? ConfigurationStatus.ready : null,
      ),
    );
  }

  Future<void> _onContinueRequested(
    ConfigurationContinueRequested event,
    Emitter<ConfigurationState> emit,
  ) async {
    final next = state.step.rank + 1;
    if (next >= ConfigurationStep.count) return;

    await _persistDraft(emit, step: next, markDone: state.step.rank);

    emit(
      state.copyWith(
        step: _stepAt(next),
        maxStep: next > state.maxStep ? next : null,
        doneSteps: {...state.doneSteps, state.step.rank},
        justSaved: false,
      ),
    );
  }

  void _onBackRequested(
    ConfigurationBackRequested event,
    Emitter<ConfigurationState> emit,
  ) {
    final previous = state.step.rank - 1;
    if (previous < 0) return;
    emit(
      state.copyWith(
        step: _stepAt(previous),
        justSaved: false,
        failure: null,
        status: state.hasFailure ? ConfigurationStatus.ready : null,
      ),
    );
  }

  Future<void> _onSaveRequested(
    ConfigurationSaveRequested event,
    Emitter<ConfigurationState> emit,
  ) async {
    await _persistDraft(emit, step: state.step.rank);
  }

  Future<void> _onDraftChanged(
    ConfigurationDraftChanged event,
    Emitter<ConfigurationState> emit,
  ) async {
    emit(
      state.copyWith(
        draft: event.draft,
        isDirty: true,
        justSaved: false,
        failure: null,
        status: state.hasFailure ? ConfigurationStatus.ready : null,
      ),
    );

    _simulationTimer?.cancel();
    if (!event.simulate || !event.draft.isSimulatable) return;

    _simulationTimer = Timer(
      simulationDebounce,
      () => add(const ConfigurationSimulationRequested()),
    );
  }

  Future<void> _onSimulationRequested(
    ConfigurationSimulationRequested event,
    Emitter<ConfigurationState> emit,
  ) async {
    if (!state.draft.isSimulatable) return;

    final generation = ++_simulationGeneration;
    emit(state.copyWith(isSimulating: true));

    final result = await _repository.simulate(state.draft);

    // Une simulation périmée n'écrase rien : ses totaux ne correspondraient à
    // aucun état coché à l'écran.
    if (generation != _simulationGeneration || isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isSimulating: false,
          status: ConfigurationStatus.failure,
          failure: failure,
          // Le plan précédent est effacé : garder des totaux d'avant l'échec
          // les ferait passer pour ceux du brouillon courant.
          plan: null,
        ),
      ),
      (plan) => emit(
        state.copyWith(
          isSimulating: false,
          status: ConfigurationStatus.ready,
          plan: plan,
          failure: null,
        ),
      ),
    );
  }

  Future<void> _onRetryRequested(
    ConfigurationRetryRequested event,
    Emitter<ConfigurationState> emit,
  ) async {
    emit(state.copyWith(status: ConfigurationStatus.loading, failure: null));

    if (event.refreshCatalog) {
      final result = await _repository.loadCatalog(forceRefresh: true);
      final failure = result.fold<Failure?>((f) => f, (_) => null);
      if (failure != null) {
        emit(
          state.copyWith(status: ConfigurationStatus.failure, failure: failure),
        );
        return;
      }
      emit(
        state.copyWith(
          catalog: result.getOrElse(() => throw StateError('unreachable')),
        ),
      );
    }

    emit(state.copyWith(status: ConfigurationStatus.ready));
    if (state.draft.isSimulatable) {
      add(const ConfigurationSimulationRequested());
    }
  }

  Future<void> _persistDraft(
    Emitter<ConfigurationState> emit, {
    required int step,
    int? markDone,
  }) async {
    final result = await _draftRepository.save(
      request: state.draft,
      step: step,
      maxStep: state.maxStep,
    );

    result.fold(
      // Une écriture qui échoue se dit : l'agent doit savoir que sa saisie ne
      // survivra pas à la fermeture de l'application.
      (failure) => emit(state.copyWith(failure: failure, justSaved: false)),
      (_) => emit(
        state.copyWith(
          isDirty: false,
          justSaved: true,
          doneSteps: markDone == null ? null : {...state.doneSteps, markDone},
        ),
      ),
    );
  }
}
