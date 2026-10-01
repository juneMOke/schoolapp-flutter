import 'package:equatable/equatable.dart';

/// La justification d'un retard ou d'une absence : un motif, une précision.
/// Chaque module tient sa liste de motifs ([R]) ; la pièce jointe est
/// reportée (V1.1).
class PresenceJustification<R extends Object> extends Equatable {
  final R reason;

  /// Précision libre, au plus [maxNoteLength] caractères.
  final String? note;

  const PresenceJustification({required this.reason, this.note});

  static const int maxNoteLength = 500;

  @override
  List<Object?> get props => [reason, note];
}
