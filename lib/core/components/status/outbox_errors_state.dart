import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/core/offline/outbox_author_directory.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';

/// Phase de chargement de la liste des écritures en échec.
enum OutboxErrorsStatus { loading, loaded, failure }

/// État de la feuille de reprise (`SyncErrorsSheet`).
///
/// [busy] couvre une action en cours (requeue / flush) : il verrouille les
/// boutons sans masquer la liste — un rejeu d'argent ne doit jamais pouvoir
/// être déclenché deux fois par un double tap.
class OutboxErrorsState extends Equatable {
  final OutboxErrorsStatus status;
  final List<OutboxEntry> entries;
  final bool busy;

  /// Ce qui reste en file au nom d'AUTRES comptes de la tablette.
  ///
  /// La garde d'attribution du moteur met ces écritures en attente propre au
  /// lieu de les pousser sous le mauvais jeton. Sans cet agrégat, cette
  /// protection serait invisible : la pastille afficherait « à envoyer » pour
  /// des entrées qui ne partiront jamais tant que leur auteur n'est pas revenu,
  /// et personne ne saurait pourquoi.
  final OtherAuthorsPending others;

  /// MES écritures en attente que le moteur a délibérément RETENUES, avec leur
  /// motif (`lastError`, écrit par `defer`). Typiquement un paiement qui attend
  /// l'inscription de son élève : sans cette liste, une écriture d'argent reste
  /// en file sans que rien ne dise pourquoi.
  final List<OutboxEntry> held;

  /// Identités résolues des comptes de [others], dans le même ordre que
  /// `others.authorUids`. Une entrée peut manquer (compte jamais vu sur cette
  /// tablette) : l'affichage retombe alors sur une formulation anonyme.
  final List<OutboxAuthorIdentity?> otherAuthors;

  const OutboxErrorsState({
    this.status = OutboxErrorsStatus.loading,
    this.entries = const <OutboxEntry>[],
    this.busy = false,
    this.others = OtherAuthorsPending.none,
    this.held = const <OutboxEntry>[],
    this.otherAuthors = const <OutboxAuthorIdentity?>[],
  });

  /// Vrai quand il n'y a RIEN à montrer : ni erreur à soi, ni attente d'autrui.
  bool get isEmpty =>
      status == OutboxErrorsStatus.loaded &&
      entries.isEmpty &&
      others.isEmpty &&
      held.isEmpty;

  OutboxErrorsState copyWith({
    OutboxErrorsStatus? status,
    List<OutboxEntry>? entries,
    bool? busy,
    OtherAuthorsPending? others,
    List<OutboxEntry>? held,
    List<OutboxAuthorIdentity?>? otherAuthors,
  }) => OutboxErrorsState(
    status: status ?? this.status,
    entries: entries ?? this.entries,
    busy: busy ?? this.busy,
    others: others ?? this.others,
    held: held ?? this.held,
    otherAuthors: otherAuthors ?? this.otherAuthors,
  );

  @override
  List<Object?> get props => [
    status,
    entries,
    busy,
    held,
    others.count,
    others.oldestCreatedAt,
    others.authorUids,
    otherAuthors.map((a) => '${a?.firstName}|${a?.lastName}').toList(),
  ];
}
