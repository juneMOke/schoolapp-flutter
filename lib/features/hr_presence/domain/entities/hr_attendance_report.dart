import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Le PDF d'assiduité — pièce **AP**, composée par le serveur sur la même
/// question que le tableau de bord : mêmes lignes, même ordre.
class HrAttendanceReport extends Equatable {
  final Uint8List bytes;

  /// Le nom donné par `Content-Disposition`, ou un nom par défaut.
  final String fileName;

  const HrAttendanceReport({required this.bytes, required this.fileName});

  @override
  List<Object?> get props => [bytes, fileName];
}
