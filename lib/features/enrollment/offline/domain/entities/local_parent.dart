import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';

/// Tuteur lu depuis sqflite. `id` provisoire avant l'ACK, canonique après remap.
class LocalParent extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? surname;
  final String? phoneNumber;
  final String? email;
  final String? identificationNumber;
  final OfflineRelationshipType relationshipType;

  /// Tuteur à appeler en urgence pour l'élève de ce dossier. Comme
  /// [relationshipType], il décrit le couple (élève, tuteur) et se lit sur le
  /// lien `student_parent`, pas sur la fiche du tuteur — un même adulte peut
  /// être le contact d'urgence d'un enfant et pas de son frère.
  final bool emergencyContact;
  final SyncState syncState;

  const LocalParent({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.surname,
    this.phoneNumber,
    this.email,
    this.identificationNumber,
    this.relationshipType = OfflineRelationshipType.other,
    this.emergencyContact = false,
    this.syncState = SyncState.pendingSync,
  });

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    surname,
    phoneNumber,
    email,
    identificationNumber,
    relationshipType,
    emergencyContact,
    syncState,
  ];
}
