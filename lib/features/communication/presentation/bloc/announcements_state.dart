import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_filters.dart';

enum AnnouncementsStatus { loading, ready, failure }

/// La liste des communiqués de l'année et ses critères.
class AnnouncementsState extends Equatable {
  final AnnouncementsStatus status;
  final List<Announcement> items;
  final AnnouncementFilters filters;
  final Failure? failure;

  const AnnouncementsState({
    this.status = AnnouncementsStatus.loading,
    this.items = const [],
    this.filters = const AnnouncementFilters(),
    this.failure,
  });

  AnnouncementsState copyWith({
    AnnouncementsStatus? status,
    List<Announcement>? items,
    AnnouncementFilters? filters,
    Failure? failure,
  }) => AnnouncementsState(
    status: status ?? this.status,
    items: items ?? this.items,
    filters: filters ?? this.filters,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, items, filters, failure];
}
