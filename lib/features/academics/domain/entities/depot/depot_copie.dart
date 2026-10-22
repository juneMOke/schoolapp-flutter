import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/attachments/attachment_ref.dart';

/// Une page de la copie : un fichier déposé, à sa place dans l'ordre.
class DepotFichier extends Equatable {
  final String id;
  final int ordre;
  final AttachmentRef ref;

  const DepotFichier({
    required this.id,
    required this.ordre,
    required this.ref,
  });

  @override
  List<Object?> get props => [id, ordre, ref];
}

/// La copie qu'un parent a déposée pour un devoir en ligne (V180) — la plus
/// récente : un nouveau dépôt remplace le précédent.
class DepotCopie extends Equatable {
  final String id;
  final String studentId;
  final DateTime? depositedAt;

  /// Déposée après l'échéance, sous dépôt tardif permis.
  final bool enRetard;

  /// Dans l'ordre des pages.
  final List<DepotFichier> fichiers;

  /// Pages que la tablette n'a pas su lire : la copie est alors incomplète.
  final int pagesEcartees;

  const DepotCopie({
    required this.id,
    required this.studentId,
    this.depositedAt,
    this.enRetard = false,
    this.fichiers = const [],
    this.pagesEcartees = 0,
  });

  /// Toutes les pages sont lisibles, et il y en a.
  bool get isComplete => pagesEcartees == 0 && fichiers.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    studentId,
    depositedAt,
    enRetard,
    fichiers,
    pagesEcartees,
  ];
}
