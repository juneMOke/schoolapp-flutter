import 'package:equatable/equatable.dart';

/// La fiche de la photo du bon d'une dépense déclarée — **jamais ses
/// octets**, qui vivent dans le magasin chiffré du poste.
///
/// Une photo par dépense : son identifiant est celui de la dépense.
class ExpenseVoucher extends Equatable {
  final String id;
  final String contentType;
  final int sizeBytes;

  /// `null` tant que le serveur ne l'a pas reçue.
  final DateTime? uploadedAt;

  const ExpenseVoucher({
    required this.id,
    required this.contentType,
    required this.sizeBytes,
    this.uploadedAt,
  });

  bool get isPdf => contentType == 'application/pdf';

  @override
  List<Object?> get props => [id, contentType, sizeBytes, uploadedAt];
}
