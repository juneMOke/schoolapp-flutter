import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_bloc.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_note.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_objectif.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_ressource.dart';

/// Un chapitre du programme d'un cours.
///
/// La **fiche** (titre → blocs) part toujours entière : le dernier
/// enregistrement gagne, horodaté par [clientUpdatedAt]. Les [notes] et les
/// [ressources] ont leurs propres gestes ; elles ne sont chargées que par le
/// détail d'un chapitre (vides dans la liste du programme).
class Chapitre extends Equatable {
  final String id;
  final String coursId;

  /// Rang d'affichage, à partir de 0.
  final int ordre;
  final String titre;
  final String? resume;
  final ChapitreStatut statut;

  /// Séances prévues.
  final int seances;
  final String? sousPeriodeId;
  final List<ChapitreObjectif> objectifs;
  final List<String> strategies;
  final List<ChapitreBloc> blocs;
  final List<ChapitreNote> notes;
  final List<ChapitreRessource> ressources;
  final DateTime? clientUpdatedAt;
  final ProgrammeSyncState syncState;
  final String? rejectionCode;

  /// Ébauche recopiée de l'ancien référentiel, pas encore descendue : sa
  /// fiche ne se réécrit pas (cf. `course_programme_schema.dart`) — l'envoyer
  /// écraserait une fiche serveur que le poste n'a jamais vue.
  final bool awaitingDownload;

  /// Lu en ligne (un cours absent de la tablette) : aucun geste ne part.
  final bool readOnly;

  const Chapitre({
    required this.id,
    required this.coursId,
    required this.ordre,
    required this.titre,
    this.resume,
    this.statut = ChapitreStatut.planifie,
    this.seances = defaultSeances,
    this.sousPeriodeId,
    this.objectifs = const [],
    this.strategies = const [],
    this.blocs = const [],
    this.notes = const [],
    this.ressources = const [],
    this.clientUpdatedAt,
    this.syncState = ProgrammeSyncState.synced,
    this.rejectionCode,
    this.awaitingDownload = false,
    this.readOnly = false,
  });

  /// Séances prévues d'un chapitre neuf.
  static const int defaultSeances = 4;

  /// Longueur minimale d'un titre.
  static const int minTitreLength = 3;

  int get objectifsAtteints => objectifs.where((o) => o.atteint).length;

  /// Un geste peut-il partir de ce chapitre (note, ordre, suppression) ?
  bool get actionable => !readOnly;

  /// Sa fiche peut-elle être réécrite (statut, objectifs, contenu, modale) ?
  bool get editable => !readOnly && !awaitingDownload;

  /// Un chapitre « non renseigné » : ni objectif, ni note, ni ressource.
  bool get isBlank => objectifs.isEmpty && notes.isEmpty && ressources.isEmpty;

  Chapitre copyWith({
    int? ordre,
    String? titre,
    String? resume,
    bool clearResume = false,
    ChapitreStatut? statut,
    int? seances,
    String? sousPeriodeId,
    bool clearSousPeriode = false,
    List<ChapitreObjectif>? objectifs,
    List<String>? strategies,
    List<ChapitreBloc>? blocs,
    List<ChapitreNote>? notes,
    List<ChapitreRessource>? ressources,
    DateTime? clientUpdatedAt,
    ProgrammeSyncState? syncState,
  }) => Chapitre(
    id: id,
    coursId: coursId,
    ordre: ordre ?? this.ordre,
    titre: titre ?? this.titre,
    resume: clearResume ? null : (resume ?? this.resume),
    statut: statut ?? this.statut,
    seances: seances ?? this.seances,
    sousPeriodeId: clearSousPeriode
        ? null
        : (sousPeriodeId ?? this.sousPeriodeId),
    objectifs: objectifs ?? this.objectifs,
    strategies: strategies ?? this.strategies,
    blocs: blocs ?? this.blocs,
    notes: notes ?? this.notes,
    ressources: ressources ?? this.ressources,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    syncState: syncState ?? this.syncState,
    rejectionCode: rejectionCode,
    awaitingDownload: awaitingDownload,
    readOnly: readOnly,
  );

  @override
  List<Object?> get props => [
    id,
    coursId,
    ordre,
    titre,
    resume,
    statut,
    seances,
    sousPeriodeId,
    objectifs,
    strategies,
    blocs,
    notes,
    ressources,
    clientUpdatedAt,
    syncState,
    rejectionCode,
    awaitingDownload,
    readOnly,
  ];
}
