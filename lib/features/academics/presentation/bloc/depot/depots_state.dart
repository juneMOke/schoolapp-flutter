import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/attachments/attachment_availability.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/depot/copie_rendue.dart';

enum DepotsLoad { loading, ready, failure }

class DepotsState extends Equatable {
  final DepotsLoad load;
  final CopiesRendues copies;
  final AttachmentAvailability attachments;
  final Failure? failure;

  const DepotsState({
    this.load = DepotsLoad.loading,
    this.copies = CopiesRendues.empty,
    this.attachments = const AttachmentAvailability(),
    this.failure,
  });

  /// Toutes les pages de la copie s'ouvrent-elles maintenant ?
  bool canOpen(CopieRendue eleve) {
    final depot = eleve.depot;
    return depot != null &&
        depot.isComplete &&
        depot.fichiers.every((page) => attachments.canOpen(page.ref));
  }

  DepotsState copyWith({
    DepotsLoad? load,
    CopiesRendues? copies,
    AttachmentAvailability? attachments,
    Failure? failure,
  }) => DepotsState(
    load: load ?? this.load,
    copies: copies ?? this.copies,
    attachments: attachments ?? this.attachments,
    failure: failure,
  );

  @override
  List<Object?> get props => [load, copies, attachments, failure];
}
