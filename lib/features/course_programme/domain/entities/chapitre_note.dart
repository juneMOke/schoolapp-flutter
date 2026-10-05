import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';

/// Une note de séance. Ajoutée ou supprimée, jamais modifiée.
class ChapitreNote extends Equatable {
  final String id;
  final String chapitreId;
  final String texte;
  final DateTime ecriteLe;
  final String? auteur;
  final ProgrammeSyncState syncState;

  const ChapitreNote({
    required this.id,
    required this.chapitreId,
    required this.texte,
    required this.ecriteLe,
    this.auteur,
    this.syncState = ProgrammeSyncState.synced,
  });

  @override
  List<Object?> get props => [
    id,
    chapitreId,
    texte,
    ecriteLe,
    auteur,
    syncState,
  ];
}
