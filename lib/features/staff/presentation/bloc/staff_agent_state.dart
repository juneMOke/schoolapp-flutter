import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_draft_validator.dart';

/// Trois modes, une seule page : mêmes étapes, mêmes blocs.
enum StaffAgentMode { create, view, edit }

class StaffAgentState extends Equatable {
  static const int stepCount = 4;

  final StaffAgentMode mode;
  final StaffMemberDraft draft;

  /// La fiche telle qu'enregistrée — `null` tant qu'une création n'est pas
  /// enregistrée.
  final StaffMember? member;
  final int step;

  /// Étape la plus avancée atteinte (création : on n'avance qu'étape par
  /// étape).
  final int reached;

  /// Étapes dont on a déjà tenté de sortir : leurs erreurs s'affichent. Une
  /// erreur ne se montre jamais au premier regard.
  final Set<int> tried;
  final StaffDraftValidation validation;
  final bool saving;

  /// Posé une fois, juste après un enregistrement réussi : l'écran annonce
  /// « ajouté » ou « mis à jour », puis l'oublie.
  final bool justSaved;
  final Failure? failure;

  const StaffAgentState({
    required this.mode,
    required this.draft,
    required this.validation,
    this.member,
    this.step = 0,
    this.reached = 0,
    this.tried = const {},
    this.saving = false,
    this.justSaved = false,
    this.failure,
  });

  bool get isEditable => mode != StaffAgentMode.view;
  bool get isLastStep => step == stepCount - 1;

  /// Les erreurs à montrer : celles des étapes déjà tentées seulement.
  Map<StaffField, StaffFieldError> get visibleErrors => {
    for (final entry in validation.errors.entries)
      if (tried.contains(entry.key.step)) entry.key: entry.value,
  };

  Set<int> get visibleErrorSteps => {
    for (final field in visibleErrors.keys) field.step,
  };

  StaffAgentState copyWith({
    StaffAgentMode? mode,
    StaffMemberDraft? draft,
    StaffMember? member,
    int? step,
    int? reached,
    Set<int>? tried,
    StaffDraftValidation? validation,
    bool? saving,
    bool? justSaved,
    Failure? failure,
    bool clearFailure = false,
  }) => StaffAgentState(
    mode: mode ?? this.mode,
    draft: draft ?? this.draft,
    member: member ?? this.member,
    step: step ?? this.step,
    reached: reached ?? this.reached,
    tried: tried ?? this.tried,
    validation: validation ?? this.validation,
    saving: saving ?? this.saving,
    justSaved: justSaved ?? false,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    mode,
    draft,
    member,
    step,
    reached,
    tried,
    validation,
    saving,
    justSaved,
    failure,
  ];
}
