import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_refusal.dart';

/// La tablette sait déjà que le serveur refuserait la correction : rien n'est
/// écrit. Porte le même [refusal] que le 422 qu'elle épargne, pour que l'écran
/// le dise avec la même phrase.
class LevelCorrectionRefusedLocally extends ValidationFailure {
  final LevelCorrectionRefusal refusal;

  const LevelCorrectionRefusedLocally(this.refusal)
    : super('Correction refusée localement');

  @override
  List<Object?> get props => [...super.props, refusal];
}
