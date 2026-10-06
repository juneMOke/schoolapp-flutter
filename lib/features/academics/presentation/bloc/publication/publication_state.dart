import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_publication.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/publication_context.dart';

/// Issue du dernier geste, consommée une fois par l'écran (toast).
enum PublicationOutcome { none, published, withdrawn, failed }

class PublicationState extends Equatable {
  final PublicationContext context;
  final bool loaded;

  /// Élément dont l'appel est en vol ; ses boutons sont désactivés.
  final PublicationKind? inFlight;
  final PublicationOutcome outcome;
  final PublicationKind? outcomeKind;
  final Failure? failure;

  const PublicationState({
    this.context = const PublicationContext(),
    this.loaded = false,
    this.inFlight,
    this.outcome = PublicationOutcome.none,
    this.outcomeKind,
    this.failure,
  });

  PublicationState copyWith({
    PublicationContext? context,
    bool? loaded,
    PublicationKind? Function()? inFlight,
    PublicationOutcome? outcome,
    PublicationKind? Function()? outcomeKind,
    Failure? Function()? failure,
  }) => PublicationState(
    context: context ?? this.context,
    loaded: loaded ?? this.loaded,
    inFlight: inFlight != null ? inFlight() : this.inFlight,
    outcome: outcome ?? this.outcome,
    outcomeKind: outcomeKind != null ? outcomeKind() : this.outcomeKind,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [
    context,
    loaded,
    inFlight,
    outcome,
    outcomeKind,
    failure,
  ];
}
