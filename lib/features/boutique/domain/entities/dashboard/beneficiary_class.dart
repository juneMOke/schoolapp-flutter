import 'package:equatable/equatable.dart';

/// Une classe proposée au filtre de la liste des élèves.
class BeneficiaryClass extends Equatable {
  final String id;
  final String label;

  const BeneficiaryClass({required this.id, required this.label});

  @override
  List<Object?> get props => [id, label];
}
