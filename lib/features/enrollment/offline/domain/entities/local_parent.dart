import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';

/// Tuteur lu depuis sqflite. `id` provisoire avant l'ACK, canonique après remap.
class LocalParent extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? surname;
  final String phoneNumber;
  final String? email;
  final String? identificationNumber;
  final OfflineRelationshipType relationshipType;
  final SyncState syncState;

  const LocalParent({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.phoneNumber,
    this.email,
    this.identificationNumber,
    this.relationshipType = OfflineRelationshipType.other,
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
    syncState,
  ];
}
