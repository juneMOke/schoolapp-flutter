import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/copie_diffusion.dart';

class CopieState extends Equatable {
  /// Journal, la diffusion la plus récente d'abord.
  final List<CopieDiffusion> log;

  const CopieState({this.log = const []});

  int get printCount => log.where((d) => d.kind == CopieKind.print).length;
  int get shareCount => log.where((d) => d.kind == CopieKind.share).length;

  @override
  List<Object?> get props => [log];
}
