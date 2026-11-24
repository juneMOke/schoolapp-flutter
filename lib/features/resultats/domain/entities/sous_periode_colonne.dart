import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/intitule_colonne.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';

/// Colonne « sous-période » de la table roster × sous-période (vue classe).
///
/// L'ordre d'arrivée du backend est significatif (aligné index par index sur
/// les `pourcentages` de chaque ligne) : ne pas re-trier.
class SousPeriodeColonne extends Equatable {
  final String sousPeriodeId;
  final int ordre;

  /// Statut d'ouverture de la sous-période (permet à l'UI de signaler « en
  /// cours » pour une sous-période encore `OUVERTE`).
  final StatutPeriode statut;

  /// Le nom que la grille de la classe donne à la colonne ; `null` d'un
  /// serveur plus ancien.
  final IntituleColonne? intitule;

  const SousPeriodeColonne({
    required this.sousPeriodeId,
    required this.ordre,
    required this.statut,
    this.intitule,
  });

  @override
  List<Object?> get props => [sousPeriodeId, ordre, statut, intitule];
}
