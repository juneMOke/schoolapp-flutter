import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_draft_validator.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_member_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_agent_state.dart';

/// La page d'un agent : création en assistant, consultation, modification.
///
/// Une saisie réussit **localement** d'abord : la fiche est écrite sur la
/// tablette et mise en file ; le serveur répondra plus tard, dans l'accusé.
class StaffAgentCubit extends Cubit<StaffAgentState> {
  final SaveStaffMemberUseCase _save;
  final LoadStaffMemberUseCase _load;

  /// Les autres agents du fichier, pour l'avertissement d'homonymie.
  final List<StaffMember> _others;
  final String _today;

  StaffAgentCubit({
    required SaveStaffMemberUseCase save,
    required LoadStaffMemberUseCase load,
    required List<StaffMember> others,
    required String today,
    required StaffMemberDraft draft,
    StaffMember? member,
  }) : _save = save,
       _load = load,
       _others = others,
       _today = today,
       super(
         StaffAgentState(
           mode: member == null ? StaffAgentMode.create : StaffAgentMode.view,
           draft: draft,
           member: member,
           reached: member == null ? 0 : StaffAgentState.stepCount - 1,
           validation: StaffDraftValidator.validate(
             draft,
             today: today,
             others: others,
           ),
         ),
       );

  void updateDraft(StaffMemberDraft Function(StaffMemberDraft) change) {
    if (!state.isEditable) return;
    final draft = change(state.draft);
    emit(state.copyWith(draft: draft, validation: _validate(draft)));
  }

  /// Saisit le contrat initial d'une création. Sans effet hors création : un
  /// agent enregistré pose ses contrats depuis sa fiche.
  ///
  /// Le premier statut choisi date le contrat de l'entrée de l'agent, à
  /// défaut d'aujourd'hui — la date reste modifiable.
  void updateInitialContract(
    StaffContractDraft Function(StaffContractDraft) change,
  ) {
    if (state.mode != StaffAgentMode.create) return;
    var contract = change(state.initialContract ?? const StaffContractDraft());
    if (contract.kind != null && contract.effectiveFrom == null) {
      contract = contract.copyWith(
        effectiveFrom: () => state.draft.entryDate ?? _today,
      );
    }
    emit(state.copyWith(initialContract: () => contract));
  }

  /// « Enregistrer sans contrat » : la saisie entamée est oubliée.
  void clearInitialContract() {
    if (state.mode != StaffAgentMode.create) return;
    emit(state.copyWith(initialContract: () => null));
  }

  /// En création, on n'atteint une étape qu'après avoir validé la précédente ;
  /// en consultation et en modification, les étapes sont libres.
  void goTo(int step) {
    if (step < 0 || step >= StaffAgentState.stepCount) return;
    if (state.mode == StaffAgentMode.create && step > state.reached) return;
    emit(state.copyWith(step: step));
  }

  /// « Suivant » : l'étape est tentée ; ses erreurs apparaissent, et on
  /// reste tant qu'il y en a.
  void next() {
    final tried = {...state.tried, state.step};
    if (state.stepHasErrors(state.step)) {
      emit(state.copyWith(tried: tried));
      return;
    }
    final step = (state.step + 1).clamp(0, StaffAgentState.stepCount - 1);
    emit(
      state.copyWith(
        tried: tried,
        step: step,
        reached: step > state.reached ? step : state.reached,
      ),
    );
  }

  void previous() => goTo(state.step - 1);

  void startEdit() {
    final member = state.member;
    if (member == null) return;
    final draft = StaffMemberDraft.of(member);
    emit(
      state.copyWith(
        mode: StaffAgentMode.edit,
        draft: draft,
        validation: _validate(draft),
        tried: const {},
      ),
    );
  }

  /// Retour en modification = abandon des changements.
  void cancelEdit() {
    final member = state.member;
    if (member == null) return;
    final draft = StaffMemberDraft.of(member);
    emit(
      state.copyWith(
        mode: StaffAgentMode.view,
        draft: draft,
        validation: _validate(draft),
        tried: const {},
        clearFailure: true,
      ),
    );
  }

  /// La fiche modifiée diffère-t-elle de celle enregistrée ?
  bool get hasChanges {
    final member = state.member;
    if (member == null) return true;
    return state.draft != StaffMemberDraft.of(member);
  }

  /// Enregistre. Toutes les étapes sont validées ; s'il reste une erreur, on
  /// saute à la première étape fautive et rien n'est écrit.
  Future<bool> save() async {
    if (!state.isEditable || state.saving) return false;
    final validation = _validate(state.draft);
    final contractInvalid = state.contractErrors.isNotEmpty;
    if (!validation.isValid || contractInvalid) {
      emit(
        state.copyWith(
          validation: validation,
          tried: {for (var i = 0; i < StaffAgentState.stepCount; i++) i},
          // La première étape fautive, contrat compris.
          step: [
            ?validation.firstInvalidStep,
            if (contractInvalid) StaffAgentState.jobStep,
          ].reduce((a, b) => a < b ? a : b),
        ),
      );
      return false;
    }
    emit(state.copyWith(saving: true, clearFailure: true));
    final written = await _save(state.draft);
    if (isClosed) return false;
    final failure = written.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(state.copyWith(saving: false, failure: failure));
      return false;
    }
    final reloaded = await _load(state.draft.id);
    if (isClosed) return false;
    final member = reloaded.fold((_) => state.member, (m) => m);
    emit(
      state.copyWith(
        mode: StaffAgentMode.view,
        member: member,
        draft: member == null ? state.draft : StaffMemberDraft.of(member),
        saving: false,
        tried: const {},
        reached: StaffAgentState.stepCount - 1,
        justSaved: true,
        // L'écran le lit sur l'état d'avant, et le pose : il ne doit pas
        // survivre à la création, ni repartir une seconde fois.
        initialContract: () => null,
      ),
    );
    return true;
  }

  /// Relit la fiche après un geste qui ne passe pas par elle — un contrat :
  /// sa frise a changé. Sans effet en saisie, pour ne pas écraser un
  /// brouillon.
  Future<void> refreshMember() async {
    final member = state.member;
    if (member == null || state.mode != StaffAgentMode.view) return;
    final reloaded = await _load(member.id);
    if (isClosed || state.mode != StaffAgentMode.view) return;
    reloaded.fold(
      (_) {},
      (fresh) => emit(
        state.copyWith(member: fresh, draft: StaffMemberDraft.of(fresh)),
      ),
    );
  }

  StaffDraftValidation _validate(StaffMemberDraft draft) =>
      StaffDraftValidator.validate(draft, today: _today, others: _others);
}
